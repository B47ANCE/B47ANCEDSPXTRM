-- Native presentation is optional. Only explicitly calibrated models opt in;
-- no guessed default yaw/sign is applied to vanilla or third-party models.
local Access=require "lightWorks/lightWorks_ItemAccess"
local Direction=require "lightWorks/lightWorks_Direction"
local Alignment={CONTRACT_VERSION=1,MAX_PROFILES=64}
local profiles={}
local function finite(v) return type(v)=="number" and v==v and math.abs(v)<math.huge end
local function authority()
    return not(type(isClient)=="function" and isClient()==true)
end
local function text(v) return type(v)=="string" and #v>0 and #v<=128 and not v:find("[%c]") end
local function read(item)
    local ok,value=Access.call(item,"getWorldZRotation")
    return ok and finite(value) and value>=0 and value<=360 and value or nil
end
local function equal(a,b) return a and b and math.abs((a-b+180)%360-180)<=.001 end
function Alignment.register(def)
    assert(type(def)=="table" and text(def.item) and text(def.evidenceId),"exact item and calibration evidence required")
    assert(finite(def.northYaw) and def.northYaw>=0 and def.northYaw<360,"calibrated north yaw required")
    assert(def.clockwiseSign==1 or def.clockwiseSign==-1,"calibrated rotation sign required")
    assert(not profiles[def.item],"model alignment already registered")
    local count=0;for _ in pairs(profiles) do count=count+1 end
    assert(count<Alignment.MAX_PROFILES,"model alignment capacity")
    profiles[def.item]={item=def.item,northYaw=def.northYaw,clockwiseSign=def.clockwiseSign,evidenceId=def.evidenceId}
    return true
end
function Alignment.profile(item)
    local p=profiles[Access.fullType(item)];if not p then return nil end
    return {item=p.item,northYaw=p.northYaw,clockwiseSign=p.clockwiseSign,evidenceId=p.evidenceId}
end
local function backing(item)
    local ok,object=Access.call(item,"getWorldItem");local got,current=Access.call(object,"getItem")
    local placed,square=Access.call(object,"getSquare")
    return ok and got and current==item and placed and square and object or nil
end
local function transmit(object) return Access.call(object,"transmitCompleteItemToClients") end
function Alignment.apply(item)
    if not authority() then return false,"non-authority" end
    local api=rawget(_G,"lightWorks")
    if not api or not api.Config or api.Config.EnableNativeModelAlignment~=true then return false,"disabled" end
    local p=Alignment.profile(item);if not p then return false,"model not calibrated" end
    local light=api.getLightProfile(item)
    if not api.supportsWorldEmission(item) or not light or not light.emitter or light.emitter.cone~=true then return false,"directional world light required" end
    local data=Access.modData(item);local state=data and data.lightWorksWorldEmitter
    if not data or data.lightWorksNativeModelRecovery~=nil then return false,"native rotation recovery required" end
    if type(state)~="table" or state.schemaVersion~=1 then return false,"world state unavailable" end
    local dx,dy=Direction.vector(state.orientation)
    if not dx then return false,"orientation unavailable" end
    local angle=Direction.fromVector(dx,dy)
    local target=(p.northYaw+p.clockwiseSign*angle)%360
    local object=backing(item);local original=read(item)
    if not object or not original then return false,"native backing/yaw unavailable" end
    if equal(original,target) then return true,"unchanged" end
    -- Retain a durable recovery record before a native call that may throw after
    -- writing. Failure never rolls back authoritative optical orientation.
    data.lightWorksNativeModelRecovery={schemaVersion=1,original=original,target=target,evidenceId=p.evidenceId}
    Access.call(item,"transmitModData")
    local wrote=Access.call(item,"setWorldZRotation",target)
    if wrote and equal(read(item),target) and transmit(object) then
        data.lightWorksNativeModelRecovery=nil;Access.call(item,"transmitModData")
        return true,target
    end
    Access.call(item,"setWorldZRotation",original)
    if equal(read(item),original) and transmit(object) then
        data.lightWorksNativeModelRecovery=nil;Access.call(item,"transmitModData")
        return false,"rotation rolled back"
    end
    Access.call(item,"transmitModData")
    return false,"native rotation recovery required"
end
function Alignment.restore(item)
    if not authority() then return false,"non-authority" end
    local data=Access.modData(item);local record=data and data.lightWorksNativeModelRecovery
    if type(record)~="table" or record.schemaVersion~=1 or not finite(record.original)
        or record.original<0 or record.original>360 then return false,"valid recovery record required" end
    local object=backing(item);if not object then return false,"placed backing required" end
    Access.call(item,"setWorldZRotation",record.original)
    if not equal(read(item),record.original) or not transmit(object) then return false,"native rotation recovery required" end
    data.lightWorksNativeModelRecovery=nil;Access.call(item,"transmitModData")
    return true
end
return Alignment
