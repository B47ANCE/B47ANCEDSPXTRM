-- Manual debug/SP evidence only. No automatic mapping, save migration, network
-- intent or game launch. Use a disposable placed light; always restore it.
if type(isDebugEnabled)~="function" or isDebugEnabled()~=true then return {} end
local API=require "lightWorks/lightWorks_API"
local Access=require "lightWorks/lightWorks_ItemAccess"
local Direction=require "lightWorks/lightWorks_Direction"
local Probe={}
local pending
local function finite(v)return type(v)=="number" and v==v and math.abs(v)<math.huge end
local function sp()
    return not(type(isClient)=="function" and isClient()==true)
        and not(type(isServer)=="function" and isServer()==true)
end
local function yaw(item)
    local ok,value=Access.call(item,"getWorldZRotation")
    return ok and finite(value) and value>=0 and value<=360 and value or nil
end
local function writeAndVerify(item,value)
    local current=yaw(item)
    if current and math.abs(current-value)<.001 then return true end
    local ok,result=Access.call(item,"setWorldZRotation",value)
    local observed=yaw(item)
    return ok and result~=false and observed~=nil and math.abs(observed-value)<.001
end
local function restoreRecord()
    if not pending then return true,"no preview" end
    if not sp() then return false,"SP-only probe" end
    if writeAndVerify(pending.item,pending.original) then pending=nil;return true,"restored" end
    pending.status="inspection_required";return false,"native restore not verified; inspect disposable fixture"
end
local function target(item,allowUnknownYaw)
    if not sp() then return nil,"SP-only probe" end
    if not API.supportsWorldEmission(item) then return nil,"registered world-light fixture required" end
    local _,backing=Access.call(item,"getWorldItem")
    local _,contained=Access.call(backing,"getItem")
    if not backing or contained~=item then return nil,"exact placed backing required" end
    local player=type(getSpecificPlayer)=="function" and getSpecificPlayer(0)
    local _,px=Access.call(player,"getX");local _,py=Access.call(player,"getY");local _,pz=Access.call(player,"getZ")
    local _,x=Access.call(backing,"getX");local _,y=Access.call(backing,"getY");local _,z=Access.call(backing,"getZ")
    if not finite(px) or not finite(py) or not finite(pz) or not finite(x) or not finite(y) or not finite(z)
        or math.floor(pz)~=math.floor(z) or (px-x)^2+(py-y)^2>9 then return nil,"nearby same-floor fixture required" end
    local angle=yaw(item);if angle==nil and not allowUnknownYaw then return nil,"bounded native yaw unavailable" end
    return {backing=backing,yaw=angle}
end
function Probe.inspect(item)
    local view,reason=target(item);if not view then return nil,reason end
    local data=Access.modData(item)
    local world=type(data)=="table" and data.lightWorksWorldEmitter
    return {itemType=Access.fullType(item),nativeYaw=view.yaw,
        logicalOrientation=type(world)=="table" and Direction.normalize(world.orientation) or nil,
        preview=pending and pending.item==item and pending.preview or nil,
        original=pending and pending.item==item and pending.original or nil,
        status=pending and pending.item==item and pending.status or "clear",
        interpretation="native field readback only; visual/model alignment NOT TESTED"}
end
function Probe.preview(item,angle)
    if not finite(angle) or angle<0 or angle>=360 then return false,"angle must be in [0,360)" end
    local view,reason=target(item);if not view then return false,reason end
    if pending and (pending.item~=item or pending.status=="inspection_required") then return false,"restore current preview first" end
    if not pending then pending={item=item,backing=view.backing,original=view.yaw,status="preview"} end
    pending.preview=angle
    if not writeAndVerify(item,angle) then
        local restored,restoreReason=restoreRecord()
        return false,restored and "native preview failed; original verified" or restoreReason
    end
    return true,Probe.inspect(item)
end
function Probe.restore(item)
    if item==nil and pending then item=pending.item end
    if pending and pending.item~=item then return false,"exact previewed item required" end
    if pending then
        -- Picked-up owned fixtures can still be restored; no remote objects.
        local placed=target(item,true)
        if not placed and not(sp() and Access.ownsInventoryItem(getSpecificPlayer and getSpecificPlayer(0),item)) then
            return false,"previewed fixture must be nearby or owned"
        end
    end
    return restoreRecord()
end
function Probe.status()
    return {pending=pending~=nil,itemType=pending and Access.fullType(pending.item) or nil,
        original=pending and pending.original or nil,preview=pending and pending.preview or nil,
        status=pending and pending.status or "clear"}
end
if Events and Events.OnObjectAboutToBeRemoved then Events.OnObjectAboutToBeRemoved.Add(function(object)
    if pending and pending.backing==object then
        local ok,reason=restoreRecord()
        if not ok then print("[lightWorks][ModelRotationProbe] "..tostring(reason)) end
    end
end) end
LWModelRotationInspect=Probe.inspect
LWModelRotationPreview=Probe.preview
LWModelRotationRestore=Probe.restore
LWModelRotationStatus=Probe.status
return Probe
