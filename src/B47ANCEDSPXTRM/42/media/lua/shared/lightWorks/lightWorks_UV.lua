require "lightWorks/lightWorks_API"

local lightWorks = lightWorks
lightWorks.UV = lightWorks.UV or {}
local UV = lightWorks.UV

UV.Sources = UV.Sources or {}
UV.Modifiers = UV.Modifiers or {}
UV.CONE_DOT_THRESHOLD = UV.CONE_DOT_THRESHOLD or 0.45

local function finite(value)
    value=tonumber(value)
    if not value or value~=value or value==math.huge or value==-math.huge then return nil end
    return value
end

local function clamp(value, low, high)
    return math.max(low, math.min(high, finite(value) or 0))
end

local function call(object, method, ...)
    if not object then return false, nil end
    local ok, fn = pcall(function() return object[method] end)
    if not ok or type(fn) ~= "function" then return false, nil end
    return pcall(fn, object, ...)
end

local function squareOf(entityOrSquare)
    if not entityOrSquare then return nil end
    local ok, square = call(entityOrSquare, "getSquare")
    return ok and square or entityOrSquare
end

function UV.registerSource(definition)
    assert(type(definition) == "table" and type(definition.id) == "string" and definition.id ~= "",
        "UV source id is required")
    local source = {}
    for key, value in pairs(definition) do source[key] = value end
    source.sourceKind = source.sourceKind or "artificial"
    source.spectrum = source.spectrum or {}
    UV.Sources[source.id] = source
    return source
end

function UV.unregisterSource(id)
    local existed = UV.Sources[id] ~= nil
    UV.Sources[id] = nil
    return existed
end

function UV.getSource(id) return UV.Sources[id] end

function UV.registerExposureModifier(id, callback)
    assert(type(id) == "string" and id ~= "", "modifier id is required")
    assert(type(callback) == "function", "modifier callback is required")
    UV.Modifiers[id] = callback
end

function UV.getDayLightStrength()
    local managerOk,manager = pcall(function() return getClimateManager and getClimateManager()
        or (ClimateManager and ClimateManager.getInstance and ClimateManager.getInstance())
        or nil end)
    if not managerOk or not manager then return 0,false end
    local ok, value = call(manager, "getDayLightStrength")
    local known=ok and finite(value)~=nil
    return known and clamp(value, 0, 1) or 0,known
end

function UV.getSunlightExposure(entityOrSquare)
    local square = squareOf(entityOrSquare)
    local outside,complete = false,false
    if square then
        local ok, value = call(square, "isOutside")
        outside = ok and value == true
        complete=ok and type(value)=="boolean"
    end
    local raw=0
    if outside then
        local known
        raw,known=UV.getDayLightStrength()
        complete=complete and known
    end
    local modifier, details = 1, {}
    for id, provider in pairs(UV.Modifiers) do
        local ok, value = pcall(provider, entityOrSquare, square, raw)
        value=ok and finite(value) or nil
        if value then
            modifier = modifier * math.max(0, value)
            details[id] = value
        else
            complete=false
        end
    end
    if not finite(modifier) then complete=false end
    local natural = clamp(raw * modifier, 0, 1)
    return {
        visible = natural,
        uv = {
            total = natural, natural = natural, artificial = 0,
            complete=complete,
            uva = natural, uvb = natural, uvc = 0,
            exposed = natural > 0, dominantSource = natural > 0 and "sunlight" or nil,
            sources = natural > 0 and {{id="sunlight", sourceKind="natural", intensity=natural}} or {},
            occlusion = outside and (1 - clamp(modifier, 0, 1)) or 1,
        },
        context = {outside=outside, rawDaylight=raw, modifier=modifier, modifiers=details},
    }
end

local function bulbEmitter(light)
    if not light or not lightWorks.isRegisteredLight(light) or not lightWorks.hasBulb(light)
        or (lightWorks.isBulbBurnedOut and lightWorks.isBulbBurnedOut(light)) then return nil end
    local power=(rawget(_G,"B47ANCEDPower")or rawget(_G,"powerWorks")or lightWorks.powerWorks)
    if type(power)=="table" and type(power.isRegisteredConsumer)=="function" then
        local registeredOk,registered=pcall(power.isRegisteredConsumer,light)
        if registeredOk and registered==true then
            if type(power.getConsumerPowerState)~="function" then return nil end
            local stateOk,state=pcall(power.getConsumerPowerState,light)
            if not stateOk or type(state)~="table" or state.known~=true or state.powered~=true then return nil end
        end
    end
    local emission = lightWorks.getEmission(light, "UV")
    if not emission and not lightWorks.getBulbTag(light, "UV") then return nil end
    local data = type(emission) == "table" and emission or {}
    return {
        item=light, sourceKind="artificial", class=data.class or lightWorks.getCustom(light, "uvClass"),
        intensity=math.max(0,finite(data.intensity) or finite(emission) or finite(lightWorks.getCustom(light, "uvStrength")) or 1),
        range=math.max(0.01,finite(data.range) or finite(lightWorks.getCustom(light, "uvRange")) or 9),
        spectrum=data.spectrum or {uva=1, uvb=0, uvc=0}, directional=true,
    }
end

local function worldBulbEmitter(light)
    local okBulb,bulbType=call(light,"getBulbItem")
    local profile=okBulb and lightWorks.getBulbProfile and lightWorks.getBulbProfile(bulbType) or nil
    local emission=profile and profile.emissions and profile.emissions.UV or nil
    if not emission and not (profile and profile.tags and profile.tags.UV) then return nil end
    local okActive,isActive=call(light,"isActivated")
    if okActive and isActive~=true then return nil end
    local data=type(emission)=="table" and emission or {}
    return {
        item=light, bulbType=bulbType, owner=light, sourceKind="artificial",
        class=data.class or (profile.custom and profile.custom.uvClass),
        intensity=math.max(0,finite(data.intensity) or finite(emission) or finite(profile.custom and profile.custom.uvStrength) or 1),
        range=math.max(0.01,finite(data.range) or finite(profile.custom and profile.custom.uvRange) or 9),
        spectrum=data.spectrum or {uva=1,uvb=0,uvc=0}, directional=false,
    }
end

function UV.collectWorldEmitters(center,radius)
    local sources=lightWorks.EmissionSources
    if not sources then
        local ok,value=pcall(require,"lightWorks/lightWorks_EmissionSources")
        if ok then sources=value end
    end
    if sources and type(sources.collectWorld)=="function" then
        local result={}
        for _,source in ipairs(sources.collectWorld(center,radius,128)) do
            if source.channels and source.channels.UV and (finite(source.uvIntensity) or 0)>0 then
                result[#result+1]={item=source.backingItem or source.object,owner=source.object,
                    sourceKind="artificial",class=source.class,
                    intensity=source.uvIntensity,range=source.uvRange,
                    spectrum=source.spectrum or {uva=1,uvb=0,uvc=0},directional=source.directional==true,
                    directionX=source.directionX,directionY=source.directionY,orientation=source.orientation,
                    mode=source.mode,effectIntensity=source.effectIntensity,providerId=source.providerId}
            end
        end
        return result
    end
    radius=math.floor(math.max(1,math.min(finite(radius) or 16,32)))
    local cell=getCell and getCell() or nil
    if not cell or not center then return {} end
    local _,cx=call(center,"getX"); local _,cy=call(center,"getY"); local _,cz=call(center,"getZ")
    cx,cy,cz=finite(cx),finite(cy),finite(cz)
    if not cx or not cy or not cz then return {} end
    cx,cy,cz=math.floor(cx),math.floor(cy),math.floor(cz)
    local emitters={}
    for x=cx-radius,cx+radius do
        for y=cy-radius,cy+radius do
            local okSquare,square=call(cell,"getGridSquare",x,y,cz)
            if okSquare and square then
                local okObjects,objects=call(square,"getObjects")
                local _,count=call(objects,"size")
                count=finite(count)
                count=count and math.min(4096,math.max(0,math.floor(count))) or 0
                for index=0,count-1 do
                    local _,object=call(objects,"get",index)
                    local emitter=worldBulbEmitter(object)
                    if emitter then emitters[#emitters+1]=emitter end
                end
            end
        end
    end
    return emitters
end

local function active(item)
    local ok, value = call(item, "isActivated")
    if not ok then ok, value = call(item, "getActivated") end
    return ok and value == true
end

function UV.collectPlayerEmitters(player)
    local emitters, seen = {}, {}
    local nativeActive={}
    if ArrayList and type(ArrayList.new)=="function" then
        local list=ArrayList.new()
        local collected=pcall(function() player:getActiveLightItems(list) end)
        if collected then
            local _,count=call(list,"size")
            for index=0,math.min(8,math.max(0,tonumber(count) or 0))-1 do
                local _,item=call(list,"get",index)
                if item then
                    nativeActive[item]=true
                    local partOk,part=call(item,"getActiveLight")
                    if partOk and part then nativeActive[part]=true end
                end
            end
        end
    end
    local function add(item, slot, forcedActive)
        if not item or seen[item] then return end
        seen[item] = true
        local emitter = bulbEmitter(item)
        if emitter and (forcedActive==true or nativeActive[item]==true or active(item)) then
            emitter.owner, emitter.slot = player, slot
            emitters[#emitters + 1] = emitter
        end
    end
    local function weaponParts(item, slot)
        local ok, parts = call(item, "getAllWeaponParts")
        if not ok or not parts then return end
        local _, size = call(parts, "size")
        size=finite(size); size=size and math.min(128,math.max(0,math.floor(size))) or 0
        for index=0,size-1 do
            local _,part=call(parts,"get",index)
            add(part,slot.."-weapon-part",nativeActive[item]==true or nativeActive[part]==true)
        end
    end
    local _, primary = call(player, "getPrimaryHandItem")
    local _, secondary = call(player, "getSecondaryHandItem")
    add(primary,"primary-hand"); add(secondary,"secondary-hand")
    weaponParts(primary,"primary"); if secondary ~= primary then weaponParts(secondary,"secondary") end
    local okAttached, attached = call(player, "getAttachedItems")
    if okAttached and attached then
        local _, size = call(attached, "size")
        size=finite(size); size=size and math.min(128,math.max(0,math.floor(size))) or 0
        for index=0,size-1 do
            local itemOk,item=call(attached,"getItemByIndex",index)
            if not itemOk or not item then
                itemOk,item=call(attached,"get",index)
                local wrapperOk,wrapped=call(item,"getItem")
                if wrapperOk and wrapped then item=wrapped end
            end
            add(item,"attached",nativeActive[item]==true); weaponParts(item,"attached")
        end
    end
    return emitters
end

local function sourceContribution(entity, emitter)
    if type(emitter)~="table" then return nil,"invalid emitter" end
    local owner = emitter.owner
    if not entity or not owner then return nil,"missing owner or target" end
    local _, ez=call(entity,"getZ"); local _, oz=call(owner,"getZ")
    ez,oz=finite(ez),finite(oz)
    if not ez or not oz then return nil,"invalid floor" end
    if math.floor(ez)~=math.floor(oz) then return nil end
    local _, ex=call(entity,"getX"); local _, ey=call(entity,"getY")
    local _, ox=call(owner,"getX"); local _, oy=call(owner,"getY")
    ex,ey,ox,oy=finite(ex),finite(ey),finite(ox),finite(oy)
    local range,intensity=finite(emitter.range),finite(emitter.intensity)
    if not ex or not ey or not ox or not oy or not range or range<=0 or not intensity or intensity<0 then return nil,"invalid emission geometry" end
    if intensity==0 then return nil end
    local dx,dy=ex-ox,ey-oy
    local distance=math.sqrt(dx*dx+dy*dy); if distance > range then return nil end
    if emitter.directional and distance > 0.0001 then
        local fx,fy=finite(emitter.directionX),finite(emitter.directionY)
        if not fx or not fy then
            local okDir,dir=call(owner,"getDir");if not okDir or not dir then return nil,"unknown direction" end
            local okVector,vector=call(dir,"ToVector");if not okVector or not vector then return nil,"unknown direction" end
            _,fx=call(vector,"getX");_,fy=call(vector,"getY");fx,fy=finite(fx),finite(fy)
        end
        if not fx or not fy or (fx==0 and fy==0) then return nil,"invalid direction" end
        if (dx/distance)*fx+(dy/distance)*fy < (finite(UV.CONE_DOT_THRESHOLD) or 0.45) then return nil end
    end
    local falloff=math.max(0.20,1-(distance/range)*0.65)
    intensity=math.max(0,intensity*falloff)
    return {source=emitter,item=emitter.item,sourceKind="artificial",class=emitter.class,
        intensity=intensity,distance=distance,falloff=falloff,spectrum=emitter.spectrum}
end

local function position(object)
    local _,x=call(object,"getX"); local _,y=call(object,"getY"); local _,z=call(object,"getZ")
    return {x=finite(x),y=finite(y),z=finite(z)}
end

function UV.getArtificialExposure(entity, emitters, context)
    local sources,total,uva,uvb,uvc={},0,0,0,0
    local strict=type(context)=="table" and context.checkOcclusion==true
    local complete,blocked,unknown,checked=true,0,0,0
    local obstruction
    if strict then obstruction=require "lightWorks/lightWorks_UVOcclusion" end
    if type(emitters)~="table" then emitters={}; complete=not strict end
    for index, emitter in ipairs(emitters) do
        if strict and index>64 then complete=false; break end
        local contribution,invalid=sourceContribution(entity,emitter)
        if strict and invalid then unknown=unknown+1; complete=false end
        if contribution then
            if strict then
                checked=checked+1
                local transmission,reason=obstruction.trace(context.cell,position(emitter.owner),position(entity),context)
                if transmission==nil then
                    unknown=unknown+1; complete=false; contribution=nil
                elseif transmission<=0 then
                    blocked=blocked+1; contribution=nil
                else
                    contribution.unoccludedIntensity=contribution.intensity
                    contribution.intensity=contribution.intensity*transmission
                    contribution.transmission=transmission
                    contribution.occlusionReason=reason
                end
            end
        end
        if contribution then
            local spectrum=type(contribution.spectrum)=="table" and contribution.spectrum or {}
            local valid=contribution.spectrum==nil or type(contribution.spectrum)=="table"
            for _,band in ipairs({"uva","uvb","uvc"}) do
                if spectrum[band]~=nil and (not finite(spectrum[band]) or finite(spectrum[band])<0) then valid=false end
            end
            local nt=total+contribution.intensity
            local na=uva+contribution.intensity*math.max(0,finite(spectrum.uva) or 1)
            local nb=uvb+contribution.intensity*math.max(0,finite(spectrum.uvb) or 0)
            local nc=uvc+contribution.intensity*math.max(0,finite(spectrum.uvc) or 0)
            if not finite(nt) or not finite(na) or not finite(nb) or not finite(nc) or (strict and not valid) then
                complete=false; unknown=unknown+1
            else
                sources[#sources+1]=contribution; total,uva,uvb,uvc=nt,na,nb,nc
            end
        end
    end
    return {visible=0,uv={total=total,natural=0,artificial=total,uva=uva,uvb=uvb,uvc=uvc,
        exposed=total>0,dominantSource=sources[1] and sources[1].source or nil,sources=sources,occlusion=0,
        occlusionChecked=strict,complete=complete,blockedSources=blocked,unknownSources=unknown,checkedSources=checked}}
end

-- New tissue consumers must use this path and require uv.complete before
-- advancing dose; incomplete geometry is not proof of zero exposure.
function UV.getOccludedArtificialExposure(entity,emitters,context)
    context=type(context)=="table" and context or {}
    local cell=context.cell
    if not cell and type(getCell)=="function" then
        local ok,value=pcall(getCell)
        if ok then cell=value end
    end
    return UV.getArtificialExposure(entity,emitters,{checkOcclusion=true,cell=cell,
        windowTransmission=context.windowTransmission})
end

function UV.getExposure(entity, context)
    local natural=UV.getSunlightExposure(entity)
    local strict=type(context)=="table" and context.checkOcclusion==true
    local artificial=strict and UV.getOccludedArtificialExposure(entity,context.emitters or {},context)
        or UV.getArtificialExposure(entity,context and context.emitters or {})
    local result=natural
    result.uv.complete=natural.uv.complete==true and artificial.uv.complete==true
    result.uv.occlusionChecked=artificial.uv.occlusionChecked
    result.uv.blockedSources=artificial.uv.blockedSources
    result.uv.unknownSources=artificial.uv.unknownSources
    result.uv.checkedSources=artificial.uv.checkedSources
    result.uv.artificial=artificial.uv.artificial
    result.uv.total=result.uv.natural+result.uv.artificial
    result.uv.uva=result.uv.uva+artificial.uv.uva
    result.uv.uvb=result.uv.uvb+artificial.uv.uvb
    result.uv.uvc=result.uv.uvc+artificial.uv.uvc
    result.uv.exposed=result.uv.total>0
    for _,source in ipairs(artificial.uv.sources) do result.uv.sources[#result.uv.sources+1]=source end
    if artificial.uv.artificial>result.uv.natural then result.uv.dominantSource=artificial.uv.dominantSource end
    return result
end

function UV.getVerifiedExposure(entity,emitters,context)
    context=type(context)=="table" and context or {}
    return UV.getExposure(entity,{checkOcclusion=true,emitters=emitters,cell=context.cell,
        windowTransmission=context.windowTransmission})
end

return UV
