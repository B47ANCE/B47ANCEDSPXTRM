local lightWorks=require "lightWorks/lightWorks_API"
pcall(require,"lightWorks/lightWorks_Patterns")
pcall(require,"lightWorks/lightWorks_LowPowerFlicker")

lightWorks.EmissionSources=lightWorks.EmissionSources or {}
local Sources=lightWorks.EmissionSources
local providers=Sources.providers or {}
Sources.providers=providers

local function finite(value)
    value=tonumber(value)
    return value and value==value and value~=math.huge and value~=-math.huge and value or nil
end

local function call(object,method,...)
    if not object then return false,nil end
    local ok,fn=pcall(function()return object[method]end)
    if not ok or type(fn)~="function" then return false,nil end
    return pcall(fn,object,...)
end

local function position(object)
    if type(object)=="table" then
        local tx,ty,tz=finite(object.x),finite(object.y),finite(object.z)
        if tx and ty and tz then return tx,ty,tz end
    end
    local ox,x=call(object,"getX");local oy,y=call(object,"getY");local oz,z=call(object,"getZ")
    x,y,z=ox and finite(x),oy and finite(y),oz and finite(z)
    if not x or not y or not z then
        local ok,square=call(object,"getSquare")
        if ok and square then
            _,x=call(square,"getX");_,y=call(square,"getY");_,z=call(square,"getZ")
            x,y,z=finite(x),finite(y),finite(z)
        end
    end
    return x,y,z
end

local function active(object)
    for _,method in ipairs({"isActivated","getActivated","isActive"}) do
        local ok,value=call(object,method)
        if ok then return value==true end
    end
    return nil
end

local function method(object,name)
    local ok,value=pcall(function()return object and object[name]end)
    return ok and type(value)=="function"
end

local function physicalThump(object,pawn)
    if not object or not pawn then return false,"missing physical attacker or target" end
    local target=object
    if method(object,"getThumpableFor") then
        local ok,value=call(object,"getThumpableFor",pawn)
        if not ok or not value then return false,"object rejected zombie thumping" end
        target=value
    end
    if not method(target,"Thump") then return false,"resolved object has no engine Thump method" end
    local ok=pcall(function()target:Thump(pawn,1)end)
    return ok,ok and nil or "engine Thump call failed"
end

local function powered(object)
    local power=rawget(_G,"powerWorks")
    if type(power)=="table" and type(power.isRegisteredConsumer)=="function" then
        local ok,registered=pcall(power.isRegisteredConsumer,object)
        if ok and registered==true then
            if type(power.getConsumerPowerState)~="function" then return nil end
            local read,state=pcall(power.getConsumerPowerState,object)
            return read and type(state)=="table" and state.known==true and state.powered==true or false
        end
    end
    local on=active(object)
    return on==true and true or nil
end

local function copy(value,depth)
    if type(value)~="table" then return value end
    depth=(depth or 0)+1;if depth>4 then return nil end
    local result={};for key,entry in pairs(value) do result[key]=copy(entry,depth) end;return result
end

local function persistedDirection(object)
    local ok,data=call(object,"getModData");local state=ok and type(data)=="table" and data.lightWorksWorldEmitter or nil
    local facing=state and string.upper(tostring(state.orientation or"")) or""
    facing=string.match(facing,"([NSEW]+)$") or facing
    local vectors={N={0,-1},NE={.707,-.707},E={1,0},SE={.707,.707},S={0,1},SW={-.707,.707},W={-1,0},NW={-.707,-.707}}
    local vector=vectors[facing];return vector and vector[1] or nil,vector and vector[2] or nil,facing~=""and facing or nil
end

function Sources.registerProvider(definition)
    assert(type(definition)=="table" and type(definition.id)=="string" and definition.id~="","emission-source provider id is required")
    assert(type(definition.inspect)=="function","emission-source provider inspect callback is required")
    providers[definition.id]={id=definition.id,priority=finite(definition.priority) or 0,inspect=definition.inspect}
    return providers[definition.id]
end

function Sources.unregisterProvider(id)local existed=providers[id]~=nil;providers[id]=nil;return existed end

-- Providers may expose physical destruction only through this explicit
-- contract. requestAttack must issue or configure an engine-native physical
-- attack; consumers must never call it as a disguised setOn(false).
function Sources.requestPhysicalAttack(source,pawn)
    local destruction=type(source)=="table" and source.destroy or nil
    if type(destruction)~="table" or destruction.supported~=true or type(destruction.requestAttack)~="function" then
        return false,"source has no verified physical-attack provider"
    end
    local ok,result,reason=pcall(destruction.requestAttack,pawn,source.object,source)
    if not ok then return false,"physical-attack provider failed" end
    return result==true,result==true and nil or (reason or "physical attack was rejected")
end

local function orderedProviders()
    local result={};for _,provider in pairs(providers)do result[#result+1]=provider end
    table.sort(result,function(a,b)if a.priority==b.priority then return a.id<b.id end;return a.priority>b.priority end)
    return result
end

function Sources.inspect(object,context)
    if not object then return nil,"missing source object" end
    for _,provider in ipairs(orderedProviders()) do
        local ok,result=pcall(provider.inspect,object,context or {})
        if ok and type(result)=="table" then
            -- Fail closed: all three facts must be positively known. A fixture
            -- identity or installed bulb alone never proves current emission.
            if result.powered==true and result.on==true and result.emitting==true then
                local x,y,z=position(object)
                x,y,z=finite(result.x) or x,finite(result.y) or y,finite(result.z) or z
                if x and y and z then
                    local backingItem=result.backingItem
                    result=copy(result);result.object=object;result.backingItem=backingItem;result.providerId=provider.id
                    result.x,result.y,result.z=x,y,z
                    result.range=math.max(0,finite(result.range) or 0)
                    result.intensity=math.max(0,finite(result.intensity) or 0)
                    result.channels=type(result.channels)=="table" and result.channels or {visible=true}
                    return result
                end
            end
            return nil,result.reason or "source is not confirmed emitting"
        end
    end
    return nil,"no emission-source provider recognized object"
end

function Sources.collectWorld(center,radius,limit)
    radius=math.max(1,math.min(32,math.floor(finite(radius) or 16)))
    limit=math.max(1,math.min(512,math.floor(finite(limit) or 128)))
    local cell=rawget(_G,"getCell") and getCell() or nil
    local cx,cy,cz=position(center)
    if not cell or not cx then return {} end
    cx,cy,cz=math.floor(cx),math.floor(cy),math.floor(cz)
    local result,seen={},{}
    for x=cx-radius,cx+radius do
        for y=cy-radius,cy+radius do
            if (x-cx)^2+(y-cy)^2<=radius^2 then
                local ok,square=pcall(function()return cell:getGridSquare(x,y,cz)end)
                if ok and square then
                    -- Fixtures and IsoWorldInventoryObject instances live in
                    -- separate square collections in Build 42. Inspect both,
                    -- with identity de-duplication and the caller's hard cap.
                    for _,getter in ipairs({"getObjects","getWorldObjects"}) do
                        local got,objects=call(square,getter);local count
                        if got and objects then local countOk;countOk,count=call(objects,"size");if not countOk then count=nil end end
                        count=math.min(4096,math.max(0,math.floor(finite(count) or 0)))
                        for index=0,count-1 do
                            local read,object=call(objects,"get",index)
                            if read and object and not seen[object] then
                                seen[object]=true;local source=Sources.inspect(object,{center=center})
                                if source then result[#result+1]=source;if #result>=limit then return result end end
                            end
                        end
                    end
                end
            end
        end
    end
    return result
end

Sources.registerProvider{
    id="lightWorks.registered-light",priority=100,
    inspect=function(object)
        -- IsoWorldInventoryObject is only the physical backing. Bulb, power,
        -- activation and pattern state remain authoritative on its item.
        local backingObject=object
        local wrappedOk,wrapped=call(object,"getItem")
        if wrappedOk and wrapped then object=wrapped end
        local bulbType
        local ok,value=call(object,"getBulbItem")
        if ok then bulbType=value elseif lightWorks.isRegisteredLight(object) then bulbType=lightWorks.getInstalledBulbType(object) end
        local bulb=bulbType and lightWorks.getBulbProfile(bulbType) or nil
        if not bulb and not lightWorks.isRegisteredLight(object) then return nil end
        local isOn=active(object)
        if wrappedOk and wrapped then
            local mdOk,md=call(object,"getModData");local worldState=mdOk and type(md)=="table"and md.lightWorksWorldEmitter or nil
            if type(worldState)=="table"and type(worldState.active)=="boolean"then isOn=worldState.active end
        end
        local hasPower=powered(object)
        if isOn~=true or hasPower~=true then return {on=isOn==true,powered=hasPower==true,emitting=false,reason="inactive or power unresolved"} end
        if lightWorks.isBulbBurnedOut and lightWorks.isBulbBurnedOut(object) then return {on=true,powered=true,emitting=false,reason="burned out"} end
        local profile=lightWorks.getLightProfile(object) or {}
        local emitter=profile.emitter or {}
        local emissions=bulb and bulb.emissions or lightWorks.getEmissionProfile(object)
        local channels={visible=true}
        if type(emissions)=="table" and emissions.UV~=nil then channels.UV=true end
        local effect=1;local mode="steady"
        if lightWorks.Patterns and type(lightWorks.Patterns.evaluate)=="function" then effect,mode=lightWorks.Patterns.evaluate(object) end
        if lightWorks.LowPowerFlicker and type(lightWorks.LowPowerFlicker.shouldRender)=="function" then
            local visible=lightWorks.LowPowerFlicker.shouldRender(object);if visible==false then effect=0 end
        end
        if effect<=0 then return {on=true,powered=true,emitting=false,reason="effect off phase",mode=mode,effectIntensity=0} end
        local uv=type(emissions)=="table" and type(emissions.UV)=="table" and emissions.UV or nil
        local directionX,directionY,orientation=persistedDirection(object)
        local thumpable=method(backingObject,"getThumpableFor") and method(backingObject,"Thump")
        return {on=true,powered=true,emitting=true,bulbType=bulbType,channels=channels,
            object=backingObject,backingItem=object,
            range=finite(emitter.range) or 0,intensity=(finite(emitter.strength) or 1)*effect,
            visibleRange=finite(emitter.range) or 0,visibleIntensity=(finite(emitter.strength) or 1)*effect,
            uvRange=uv and (finite(uv.range) or finite(emitter.range) or 0) or 0,
            uvIntensity=uv and (finite(uv.intensity) or 1)*effect or 0,
            spectrum=uv and uv.spectrum or nil,mode=mode,effectIntensity=effect,
            directionX=directionX,directionY=directionY,orientation=orientation,
            directional=emitter.cone==true,destroy=thumpable
                and {supported=true,mode="engine-thump",requestAttack=function(pawn,target)return physicalThump(target,pawn)end}
                or {supported=false,reason="no engine Thump contract"}}
    end,
}

return Sources
