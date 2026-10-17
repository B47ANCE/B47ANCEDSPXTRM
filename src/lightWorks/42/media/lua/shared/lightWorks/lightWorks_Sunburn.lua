local lightWorks=require "lightWorks/lightWorks_API"
local UV=require "lightWorks/lightWorks_UV"
local Operations=require "lightWorks/lightWorks_Operations"
local Notices=require "lightWorks/lightWorks_Notifications"
local Sunburn={SCHEMA_VERSION=1,MAX_DELTA_HOURS=.25,MAX_PROVIDERS=32,MAX_OPERATIONS=32}
local providers={}

local function finite(value)local n=tonumber(value);return n and n==n and n~=math.huge and n~=-math.huge and n or nil end
local function clamp(value,low,high)value=finite(value)or low;return math.max(low,math.min(high,value))end
local function authority()
    if type(isServer)=="function"and isServer()==true then return true end
    return not(type(isClient)=="function"and isClient()==true)
end
local function dataFor(character,create)
    if not character or not character.getModData then return nil,"character ModData unavailable"end
    local ok,data=pcall(function()return character:getModData()end);if not ok or type(data)~="table"then return nil,"character ModData unavailable"end
    local state=data.lightWorksSunburn
    if state==nil and create then state={schemaVersion=1,dose=0,severity=0,processedOperations={}};data.lightWorksSunburn=state end
    if state==nil then return{schemaVersion=1,dose=0,severity=0,processedOperations={}}end
    if type(state)~="table"or state.schemaVersion~=1 then return nil,"unsupported sunburn state"end
    local history=state.processedOperations
    if history==nil then history={} end
    if not Operations.validHistory(history) or type(state.dose)~="number" or not finite(state.dose) or state.dose<0 or state.dose>1
        or type(state.severity)~="number" or not finite(state.severity) or state.severity<0 or state.severity>1 then return nil,"malformed sunburn state" end
    if create and state.processedOperations==nil then state.processedOperations=history end
    return state
end
local function snapshot(state)return{schemaVersion=1,dose=clamp(state.dose,0,1),severity=clamp(state.severity,0,1),
    lastNaturalUV=clamp(state.lastNaturalUV,0,1),lastProtection=clamp(state.lastProtection,0,1),
    lastWorldAgeHours=finite(state.lastWorldAgeHours),burning=clamp(state.severity,0,1)>0}end
local function transmit(character)if character and character.transmitModData then pcall(function()character:transmitModData()end)end end

function Sunburn.registerProtectionProvider(id,callback)
    assert(type(id)=="string"and id~="","protection provider id required")
    assert(type(callback)=="function","protection provider callback required")
    assert(not providers[id],"duplicate sunburn protection provider: "..id)
    local count=0;for _ in pairs(providers)do count=count+1 end;assert(count<Sunburn.MAX_PROVIDERS,"sunburn protection provider limit reached")
    providers[id]=callback;return true
end
function Sunburn.unregisterProtectionProvider(id)local existed=providers[id]~=nil;providers[id]=nil;return existed end
function Sunburn.getProtection(character,exposure)
    local remaining=1;local details={};local complete=true
    local ids={};for id in pairs(providers)do ids[#ids+1]=id end;table.sort(ids)
    for _,id in ipairs(ids)do
        local ok,value=pcall(providers[id],character,exposure)
        value=ok and finite(value)or nil
        if value then value=clamp(value,0,1);details[id]=value;remaining=remaining*(1-value)else complete=false end
    end
    return clamp(1-remaining,0,1),details,complete
end
function Sunburn.getState(character)local state,err=dataFor(character,false);return state and snapshot(state)or nil,err end

function Sunburn.update(character,worldAgeHours)
    if lightWorks.Config.EnableSunburn==false then return Sunburn.getState(character)end
    if not authority()then return nil,"non-authority"end
    local now=finite(worldAgeHours)
    if not now and type(getGameTime)=="function"then local ok,value=pcall(function()return getGameTime():getWorldAgeHours()end);if ok then now=finite(value)end end
    if not now then return nil,"world age unavailable"end
    local state,err=dataFor(character,true);if not state then return nil,err end
    local beforeDose,beforeSeverity,beforeNatural,beforeProtection=state.dose,state.severity,state.lastNaturalUV,state.lastProtection
    local previous=finite(state.lastWorldAgeHours)
    if not previous then state.lastWorldAgeHours=now;return snapshot(state)end
    if now<=previous then return snapshot(state)end
    state.lastWorldAgeHours=now
    local elapsed=math.min(Sunburn.MAX_DELTA_HOURS,now-previous)
    local exposure=UV.getSunlightExposure(character)
    if type(exposure)~="table" or type(exposure.uv)~="table" or exposure.uv.complete~=true then
        -- The timestamp marks observation, not proof of shelter. Never replay an
        -- unknown interval later as fully sheltered or fully exposed.
        return snapshot(state),"exposure incomplete"
    end
    local natural=clamp(exposure.uv.uvb,0,1)
    local protection,details,complete=Sunburn.getProtection(character,exposure)
    if not complete then return snapshot(state),"protection incomplete" end
    local effective=natural*(1-protection)
    local first=math.max(.01,finite(lightWorks.Config.SunburnFirstDegreeDoseHours)or.75)
    local maximum=math.max(first+.01,finite(lightWorks.Config.SunburnMaximumDoseHours)or 4)
    local doseHours=clamp(state.dose,0,1)*maximum
    if effective>0 then doseHours=doseHours+effective*elapsed*math.max(0,finite(lightWorks.Config.SunburnDoseMultiplier)or 1)
    else doseHours=math.max(0,doseHours-elapsed*math.max(0,finite(lightWorks.Config.SunburnRecoveryDoseHoursPerHour)or.10))end
    state.dose=clamp(doseHours/maximum,0,1)
    state.severity=doseHours<=first and 0 or clamp((doseHours-first)/(maximum-first),0,1)
    state.lastNaturalUV=natural;state.lastProtection=protection;state.lastProtectionDetails=details
    transmit(character)
    local result=snapshot(state)
    if state.dose~=beforeDose or state.severity~=beforeSeverity or state.lastNaturalUV~=beforeNatural or state.lastProtection~=beforeProtection then
        Notices.publish("sunburn","updated",Notices.character(character),{dose=state.dose,severity=state.severity})
    end
    return result
end

function Sunburn.applyTreatment(character,amount,operationId)
    if not authority()then return false,"non-authority"end
    if type(operationId)~="string"or operationId==""or #operationId>128 then return false,"bounded operationId required"end
    amount=finite(amount);if not amount or amount<=0 then return false,"positive treatment amount required"end
    local state,err=dataFor(character,true);if not state then return false,err end
    for _,id in ipairs(state.processedOperations)do if id==operationId then return false,"duplicate operation"end end
    state.dose=clamp((finite(state.dose)or 0)-amount,0,1)
    local first=math.max(.01,finite(lightWorks.Config.SunburnFirstDegreeDoseHours)or.75)
    local maximum=math.max(first+.01,finite(lightWorks.Config.SunburnMaximumDoseHours)or 4)
    local doseHours=state.dose*maximum;state.severity=doseHours<=first and 0 or clamp((doseHours-first)/(maximum-first),0,1)
    state.processedOperations[#state.processedOperations+1]=operationId
    while #state.processedOperations>Sunburn.MAX_OPERATIONS do table.remove(state.processedOperations,1)end
    transmit(character)
    local result=snapshot(state)
    Notices.publish("sunburn","treated",Notices.character(character),{dose=state.dose,severity=state.severity,operationId=operationId})
    return true,result
end

lightWorks.Sunburn=Sunburn
return Sunburn
