local API=require "lightWorks/lightWorks_API"
local Access=require "lightWorks/lightWorks_ItemAccess"
local Migration=require "lightWorks/lightWorks_LegacyMigration"
local Exposure=require "lightWorks/lightWorks_ConsumerExposure"
local Consumers={CONTRACT_VERSION=1,MAX_CROP_PAGE=32,WATER_TREATMENT="lightWorks.uvc.v1",MEDICAL_PROCEDURE="medWorks.treatSunburn"}
local OWNER="B47ANCE/Spectrum.Nightfall.v1"
local aliases={
    {old="ProjectNightfall.UVBulb",current="ProjectNightfall.LightBulbUV"},
    {old="ProjectNightfall.HighOutputUVBulb",current="ProjectNightfall.LightBulbUVHighOutput"},
}
local aliasStatus="WAITING_FOR_BULBS"
local function authority()
    return not(type(isClient)=="function" and isClient()==true
        and not(type(isServer)=="function" and isServer()==true))
end
local function finite(v) return type(v)=="number" and v==v and math.abs(v)<math.huge end
local function validId(v) return type(v)=="string" and #v>0 and #v<=128 and not v:find("[%c]") end
function Consumers.refreshNightfall()
    local missing=0
    for _,entry in ipairs(aliases) do
        local profile=API.getBulbProfile(entry.current)
        if not profile or not profile.tags or profile.tags.PROJECT_NIGHTFALL~=true then missing=missing+1 end
        local existing=Migration.aliases[entry.old]
        if existing and (existing.item~=entry.current or existing.owner~=OWNER) then aliasStatus="CONFLICT";return false,aliasStatus end
    end
    if missing>0 then aliasStatus="WAITING_FOR_BULBS";return false,aliasStatus end
    local count=0;for _ in pairs(Migration.aliases) do count=count+1 end
    for _,entry in ipairs(aliases) do if not Migration.aliases[entry.old] then count=count+1 end end
    if count>Migration.MAX_ALIASES then aliasStatus="CAPACITY_BLOCKED";return false,aliasStatus end
    for _,entry in ipairs(aliases) do
        if not Migration.aliases[entry.old] then Migration.registerAlias(entry.old,entry.current,OWNER) end
    end
    aliasStatus="AVAILABLE";return true,aliasStatus
end
function Consumers.aliasContract()
    local result={version=1,owner=OWNER,status=aliasStatus,aliases={}}
    for _,entry in ipairs(aliases) do result.aliases[entry.old]=entry.current end
    return result
end
local function medical()
    local med=rawget(_G,"medWorks")
    return type(med)=="table" and type(med.performProcedure)=="function" and type(med.Procedures)=="table"
        and med.Procedures[Consumers.MEDICAL_PROCEDURE] and med or nil
end
function Consumers.treatSunburn(patient,amount,operationId,treatmentSource)
    if not authority() then return false,"non-authority" end
    if not validId(operationId) or not validId(treatmentSource) or not finite(amount) or amount<.01 or amount>.5 then return false,"invalid Medical request" end
    local med=medical();if not med then return false,"Medical procedure unavailable" end
    -- Medical owns reservations, locks, revalidation and recovery. Trusted
    -- callers must implement consent, consumables and their gameplay action.
    return med.performProcedure(Consumers.MEDICAL_PROCEDURE,{patient=patient,amount=amount,
        operationId=operationId,treatmentSource=treatmentSource})
end
local function waterGate(water,owner,quality,context)
    if not authority() then return false,"non-authority" end
    if API.Config.EnableWaterUVIntegration~=true then return false,"UV Water integration disabled" end
    if type(context)~="table" or not validId(context.operationId) then return false,"bounded operationId required" end
    local ok,adapter=pcall(water.getContainer,owner)
    if not ok or not adapter or not adapter.owner then return false,"water container unavailable" end
    local data=Access.modData(adapter.owner);if type(data)~="table" then return false,"water state unavailable" end
    local history=data.waterWorksTreatmentHistory
    if history~=nil then
        if type(history)~="table" then return false,"malformed Water history" end
        local count=0
        for key,record in pairs(history) do
            count=count+1
            if count>16 or type(key)~="number" or key<1 or key>16 or key~=math.floor(key)
                or type(record)~="table" then return false,"malformed Water history" end
            if record.operationId==context.operationId then return false,"duplicate operation" end
        end
        if count~=#history then return false,"sparse Water history" end
    end
    local inspectedOk,view=pcall(water.inspectContainer,owner)
    if not inspectedOk or type(view)~="table" or not finite(view.amount) or view.amount<=0 then return false,"nonempty Water container required" end
    if view.kind~="legacy-water" and (type(view.capabilities)~="table"
        or view.capabilities.waterSource~=true or view.capabilities.mixture~=false) then return false,"confirmed unmixed Water required" end
    for _,axis in ipairs({"biological","particulate","chemical","salinity","turbidity"}) do
        if type(quality)~="table" or not finite(quality[axis]) or quality[axis]<0 or quality[axis]>1 then return false,"invalid Water quality" end
    end
    if type(quality)~="table" or not finite(quality.biological) or quality.biological<=0 then return false,"no biological load to treat" end
    if not finite(quality.turbidity) or quality.turbidity>API.Config.WaterUVMaximumTurbidity then return false,"UV Water turbidity limit" end
    local sample,reason=Exposure.sample(Exposure.position(adapter.owner))
    if not sample or sample.artificialComplete~=true or not finite(sample.uv.uvc)
        or sample.uv.uvc<API.Config.WaterUVMinimumIntensity then return false,reason or "complete UVC exposure required" end
    return true
end
function Consumers.registerWater()
    local water=rawget(_G,"waterWorks")
    if type(water)~="table" then return false,"NOT_INSTALLED" end
    for _,name in ipairs({"registerTreatment","getContainer","inspectContainer","applyTreatment"}) do
        if type(water[name])~="function" then return false,"UNSUPPORTED_API" end
    end
    if type(water.Treatments)~="table" then return false,"UNSUPPORTED_API" end
    local existing=water.Treatments[Consumers.WATER_TREATMENT]
    if existing then return existing.owner=="lightWorks" and existing.contractVersion==1,"EXISTING_CONTRACT" end
    local registered,err=pcall(water.registerTreatment,{id=Consumers.WATER_TREATMENT,owner="lightWorks",contractVersion=1,
        validate=function(owner,quality,context)return waterGate(water,owner,quality,context) end,
        transform=function(quality)
            -- Deliberate gameplay pulse, not a real disinfection/dose guarantee.
            quality.biological=quality.biological*(1-API.Config.WaterUVBiologicalReduction)
            return quality
        end})
    if not registered then return false,"Water treatment registration failed: "..tostring(err) end
    local accepted=water.Treatments[Consumers.WATER_TREATMENT]
    if type(accepted)~="table" or accepted.owner~="lightWorks" or accepted.contractVersion~=1 then
        return false,"Water treatment registration not confirmed"
    end
    return true,"REGISTERED"
end
function Consumers.treatWater(owner,operationId)
    if not authority() then return false,"non-authority" end
    if not validId(operationId) then return false,"bounded operationId required" end
    local ok,reason=Consumers.registerWater();if not ok then return false,reason end
    return waterWorks.applyTreatment(owner,Consumers.WATER_TREATMENT,{operationId=operationId})
end
local function cropView(crop)
    local farm=rawget(_G,"farmWorks")
    if type(farm)~="table" or type(farm.inspectCrop)~="function" then return nil,"Farming API unavailable" end
    local ok,view=pcall(farm.inspectCrop,crop)
    if not ok or type(view)~="table" then return nil,"crop inspection unavailable" end
    local point=Exposure.point(view.x,view.y,view.z)
    if not point then return nil,"crop world position unavailable" end
    return view,point
end
local function cropResult(view,point,sample)
    -- No source references, provider callbacks or crop mutations escape here.
    local cropType=type(view.cropType)=="string" and #view.cropType<=128 and not view.cropType:find("[%c]") and view.cropType or "unknown"
    return {schemaVersion=1,cropType=cropType,x=point.x,y=point.y,z=point.z,complete=sample.complete,
        naturalVisible=sample.naturalVisible,artificialVisible=sample.artificialVisible,totalVisible=sample.totalVisible,
        uv={uva=sample.uv.uva,uvb=sample.uv.uvb,uvc=sample.uv.uvc},scope=sample.scope,radius=sample.radius,
        growthEffect="NONE",units="normalized gameplay illumination; not lux or photon flux"}
end
function Consumers.cropLighting(crop)
    local view,point=cropView(crop);if not view then return nil,point end
    local sample,reason=Exposure.sample(point);if not sample then return nil,reason end
    return cropResult(view,point,sample)
end
function Consumers.cropLightingBatch(crops,options)
    if type(crops)~="table" or (options~=nil and type(options)~="table") then return nil,"crop array and page options required" end
    options=options or {}
    local cursor,limit=options.cursor,options.limit
    if cursor==nil then cursor=0 end
    if limit==nil then limit=16 end
    if not finite(cursor) or cursor<0 or cursor~=math.floor(cursor) or not finite(limit)
        or limit<1 or limit>Consumers.MAX_CROP_PAGE or limit~=math.floor(limit) then return nil,"invalid crop page" end
    local total=#crops
    if cursor>total then return nil,"crop cursor beyond input" end
    local last=math.min(total,cursor+limit)
    local page={schemaVersion=1,results={},cursor=cursor,limit=limit,totalCandidates=total,
        nextCursor=last<total and last or nil,sampled=0,rejected=0,complete=true}
    local views,points,entries={},{},{}
    for index=cursor+1,last do
        local view,point=cropView(crops[index])
        local entry={index=index,ok=false};page.results[#page.results+1]=entry
        if view then
            views[#views+1]=view;points[#points+1]=point;entries[#entries+1]=entry
        else entry.reason=point;page.rejected=page.rejected+1;page.complete=false end
    end
    if #points>0 then
        local samples,details=Exposure.sampleMany(points)
        if not samples then
            page.complete=false;page.rejected=page.rejected+#points
            for _,entry in ipairs(entries) do entry.reason=details end
        else
            page.query=details
            for index,entry in ipairs(entries) do
                entry.ok=true;entry.observation=cropResult(views[index],points[index],samples[index])
                page.sampled=page.sampled+1
                if samples[index].complete~=true then page.complete=false end
            end
        end
    end
    return page
end
function Consumers.refresh()
    Consumers.refreshNightfall()
    local waterOk,waterReason=Consumers.registerWater()
    local farm=rawget(_G,"farmWorks")
    return {contractVersion=1,nightfall=aliasStatus,medical=medical() and "AVAILABLE" or "UNAVAILABLE",
        water=waterOk and "AVAILABLE" or waterReason,waterEnabled=API.Config.EnableWaterUVIntegration==true,
        farming=type(farm)=="table" and type(farm.inspectCrop)=="function" and "OBSERVATION_ONLY" or "UNAVAILABLE"}
end
API.ConsumerIntegrations=Consumers
Consumers.refreshNightfall()
if Events and Events.OnGameStart then Events.OnGameStart.Add(Consumers.refresh) end
if Events and Events.OnServerStarted then Events.OnServerStarted.Add(Consumers.refresh) end
return Consumers
