require "lightWorks/lightWorks_API"
require "lightWorks/lightWorks_Patterns"
require "lightWorks/lightWorks_LowPowerFlicker"
local Adapter=require "lightWorks/lightWorks_VanillaEmitterAdapter"
local lightWorks=lightWorks
local Manager={byBacking=setmetatable({},{__mode="k"}),byId={},tick=0,nextId=1,MAX_SCAN_RADIUS=12,MAX_OBJECTS=192}

local function call(object,method,...)
    if not object then return false,nil end
    local ok,fn=pcall(function() return object[method] end)
    if not ok or type(fn)~="function" then return false,nil end
    return pcall(fn,object,...)
end
local function itemOf(backing)
    local ok,item=call(backing,"getItem");return ok and item or nil
end
local function active(item)
    for _,method in ipairs({"isActivated","getActivated","isActive"}) do local ok,value=call(item,method);if ok then return value==true end end
    return false
end
local function setActive(item,value)
    for _,method in ipairs({"setActivated","setActive"}) do local ok=call(item,method,value==true);if ok then return true end end
    return false
end
local function emitterId(item)
    local mdOk,md=call(item,"getModData");if not mdOk or type(md)~="table" then return nil end
    md.lightWorksWorldEmitter=type(md.lightWorksWorldEmitter)=="table" and md.lightWorksWorldEmitter or {schemaVersion=1}
    local state=md.lightWorksWorldEmitter
    if type(state.id)~="string" or state.id=="" then
        local itemOk,itemId=call(item,"getID")
        state.id="LW-WORLD-"..tostring(itemOk and itemId or Manager.nextId);Manager.nextId=Manager.nextId+1
    end
    return state.id,state
end
local function profileFor(item)
    if not lightWorks.isRegisteredLight(item) or not lightWorks.supportsWorldEmission(item) then return nil end
    local light=lightWorks.getLightProfile(item) or {};local emitter=light.emitter or {}
    local bulb=lightWorks.getInstalledBulb(item);if not bulb then return nil end
    local color=lightWorks.getRenderedVisibleColor(bulb) or {r=1,g=1,b=1}
    return {id=light.item,bulb=bulb,color=color,radius=tonumber(emitter.range) or 6,
        intensity=tonumber(emitter.strength) or 0.7,uv=bulb.emissions and bulb.emissions.UV or nil,
        directional=emitter.cone==true,width=tonumber(emitter.width)or 0.7,
        nodes=tonumber(emitter.nodes)or 4,falloff=tonumber(emitter.falloff)or 0.72,
        pattern=lightWorks.Patterns.getPatternId(item)}
end
local function powerState(item)
    local power=rawget(_G,"powerWorks")
    if power and type(power.getConsumerPowerState)=="function" then
        local ok,state=pcall(power.getConsumerPowerState,item)
        if ok and type(state)=="table" and state.known==true then return state.powered==true,state end
    end
    return active(item),nil
end
local function clear(record)
    if record and record.sources then Adapter.removeAll(record.sources);record.sources=nil;record.source=nil
    elseif record and record.source then Adapter.remove(record.source);record.source=nil end
    if record then record.signature=nil end
end

function Manager.unregister(backing)
    local record=Manager.byBacking[backing];if not record then return false end
    clear(record);Adapter.setAttackable(backing,false);Manager.byBacking[backing]=nil;Manager.byId[record.id]=nil;return true
end

function Manager.ensure(backing,transitionActive,orientation)
    if lightWorks.Config.EnableWorldEmitters==false then Manager.unregister(backing);return nil,"world emitters disabled" end
    local item=itemOf(backing);if not item then return nil,"not a world inventory item" end
    local profile=profileFor(item)
    if not profile then Manager.unregister(backing);return nil,"unregistered or bulb-less light" end
    local id,state=emitterId(item);if not id then return nil,"item ModData unavailable" end
    if orientation~=nil then state.orientation=tostring(orientation) end
    if type(transitionActive)=="boolean" then state.active=transitionActive end
    if state.active==nil then state.active=active(item) end
    if state.active==true and not active(item) then setActive(item,true) end
    local record=Manager.byBacking[backing]
    if not record then record={id=id,backing=backing,item=item};Manager.byBacking[backing]=record;Manager.byId[id]=record end
    record.profile=profile;record.active=state.active==true;record.powered,record.powerState=powerState(item)
    record.mode=profile.pattern or "steady";record.orientation=state.orientation
    record.uvIntensity=profile.uv and (tonumber(profile.uv.intensity) or 0) or 0
    record.uvRadius=profile.uv and (tonumber(profile.uv.range) or profile.radius) or 0
    local x,y,z=Adapter.position(backing);record.x,record.y,record.z=x,y,z
    state.active=record.active;state.profileId=profile.id;state.mode=record.mode
    local phase=lightWorks.Patterns.evaluate(item)
    local flickerVisible,flicker=lightWorks.LowPowerFlicker.shouldRender(item)
    if flickerVisible==false then phase=0 end
    record.effectIntensity=phase;record.flickering=flicker and flicker.flickering==true
    record.timed=record.mode~="steady" or record.flickering
    local shouldEmit=Adapter.exists(backing) and record.active and record.powered and phase>0 and x~=nil
    if not shouldEmit then clear(record);Adapter.setAttackable(backing,false);return record end
    Adapter.setAttackable(backing,true)
    -- Fallback adapters recreate sources for phase changes. Quantization keeps
    -- pulses smooth enough without hammering the native light registry.
    local renderPhase=record.mode=="pulse" and math.floor(phase*8+.5)/8 or phase
    local orientation=string.upper(tostring(record.orientation or""))
    local signature=table.concat({math.floor(x),math.floor(y),math.floor(z),profile.color.r,profile.color.g,profile.color.b,
        profile.radius,renderPhase,tostring(profile.directional),orientation,profile.width,profile.nodes,profile.falloff},":")
    if signature~=record.signature then
        clear(record)
        if profile.directional and(orientation=="N"or orientation=="E"or orientation=="S"or orientation=="W")then
            record.sources=Adapter.createDirectional(x,y,z,profile.color,profile,renderPhase,orientation)
            record.source=record.sources and record.sources[1]or nil
        else
            local radius=math.max(1,profile.radius*math.sqrt(math.max(0.06,renderPhase)))
            record.source=Adapter.create(x,y,z,profile.color,radius)
            record.sources=record.source and{record.source}or nil
        end
        record.signature=record.source and signature or nil
    end
    return record
end

function Manager.reconcile()
    for backing,record in pairs(Manager.byBacking) do
        if not Adapter.exists(backing) or itemOf(backing)~=record.item then Manager.unregister(backing) else Manager.ensure(backing) end
    end
end

function Manager.updateTimed()
    for backing,record in pairs(Manager.byBacking) do
        if record.timed then
            if not Adapter.exists(backing) or itemOf(backing)~=record.item then Manager.unregister(backing) else Manager.ensure(backing) end
        end
    end
end

function Manager.discoverNear(player)
    if lightWorks.Config.EnableWorldEmitters==false or not player or type(getCell)~="function" then return 0 end
    local xOk,px=call(player,"getX");local yOk,py=call(player,"getY");local zOk,pz=call(player,"getZ")
    if not xOk or not yOk or not zOk then return 0 end
    px,py,pz=math.floor(px),math.floor(py),math.floor(pz);local found=0
    for x=px-Manager.MAX_SCAN_RADIUS,px+Manager.MAX_SCAN_RADIUS do for y=py-Manager.MAX_SCAN_RADIUS,py+Manager.MAX_SCAN_RADIUS do
        if (x-px)^2+(y-py)^2<=Manager.MAX_SCAN_RADIUS^2 then
            local square=getCell():getGridSquare(x,y,pz);local objects=square and square:getWorldObjects() or nil
            local count=objects and math.min(objects:size(),Manager.MAX_OBJECTS-found) or 0
            for i=0,count-1 do local object=objects:get(i);if itemOf(object) and profileFor(itemOf(object)) then Manager.ensure(object);found=found+1 end end
            if found>=Manager.MAX_OBJECTS then return found end
        end
    end end;return found
end

function Manager.inspect(id)
    local r=id and Manager.byId[id] or nil;if not r then return nil end
    local canonical=lightWorks.UV_VISIBLE_COLOR;local c=r.profile.color
    return {id=r.id,item=r.item,backing=r.backing,x=r.x,y=r.y,z=r.z,profileId=r.profile.id,mode=r.mode,
        active=r.active,powered=r.powered,visibleRGB={r=c.r,g=c.g,b=c.b},visibleRadius=r.profile.radius,
        visibleIntensity=r.profile.intensity,uvIntensity=r.uvIntensity,uvRadius=r.uvRadius,sourceBound=r.source~=nil,
        orientation=r.orientation,effectIntensity=r.effectIntensity,
        chargeFraction=r.powerState and r.powerState.chargeFraction or nil,
        batteryType=r.powerState and r.powerState.batteryType or nil,
        colorDesync=r.profile.uv~=nil and (math.abs(c.r-canonical.r)>0.001 or math.abs(c.g-canonical.g)>0.001 or math.abs(c.b-canonical.b)>0.001)}
end

function Manager.onTick()
    Manager.tick=Manager.tick+1
    if Manager.tick%5==0 then Manager.updateTimed() end
    if Manager.tick%120==0 then
        Manager.reconcile()
        if type(getSpecificPlayer)=="function" then for i=0,3 do local p=getSpecificPlayer(i);if p then Manager.discoverNear(p) end end end
    end
end

function Manager.list()
    local out={};for id,record in pairs(Manager.byId) do out[#out+1]=Manager.inspect(id) or {id=id,backing=record.backing} end
    table.sort(out,function(a,b)return tostring(a.id)<tostring(b.id)end);return out
end

lightWorks.WorldEmitterManager=Manager
return Manager
