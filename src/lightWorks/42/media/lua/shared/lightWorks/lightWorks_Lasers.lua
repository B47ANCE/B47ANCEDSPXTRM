-- Optical presentation only: no hit bonus, damage, charge or projectile owner.
local API=require "lightWorks/lightWorks_API"
local Access=require "lightWorks/lightWorks_ItemAccess"
local Direction=require "lightWorks/lightWorks_Direction"
local Occlusion=require "lightWorks/lightWorks_UVOcclusion"
local Lasers={profiles={},MAX_PROFILES=64,MAX_RANGE=32,STEP=.25}
local function finite(v) return type(v)=="number" and v==v and math.abs(v)<math.huge end
function Lasers.register(def)
    assert(type(def)=="table" and type(def.item)=="string" and #def.item<=128,"laser item type required")
    assert(not Lasers.profiles[def.item],"duplicate laser profile")
    local count=0;for _ in pairs(Lasers.profiles) do count=count+1 end
    assert(count<Lasers.MAX_PROFILES,"laser registry limit")
    local range=def.range or 16
    assert(finite(range) and range>0 and range<=Lasers.MAX_RANGE,"bounded laser range required")
    local color=def.color or {r=1,g=0,b=0}
    for _,key in ipairs({"r","g","b"}) do assert(finite(color[key]) and color[key]>=0 and color[key]<=1,"bounded laser color required") end
    Lasers.profiles[def.item]={item=def.item,range=range,color={r=color.r,g=color.g,b=color.b}}
    return true
end
function Lasers.trace(cell,source,dx,dy,range)
    if not source or not finite(source.x) or not finite(source.y) or not finite(source.z)
        or not finite(dx) or not finite(dy) or not finite(range) or range<=0 or range>Lasers.MAX_RANGE then return nil,"invalid ray" end
    local length=math.sqrt(dx*dx+dy*dy);if length<.0001 then return nil,"invalid direction" end
    dx,dy=dx/length,dy/length
    local endpoint={x=source.x,y=source.y,z=source.z,distance=0,blocked=false}
    for step=1,math.ceil(range/Lasers.STEP) do
        local distance=math.min(range,step*Lasers.STEP)
        local target={x=source.x+dx*distance,y=source.y+dy*distance,z=source.z}
        local transmission,reason=Occlusion.trace(cell,endpoint,target,{windowTransmission=1})
        if transmission==nil then return nil,reason end
        if transmission==0 then endpoint.blocked=true;return endpoint end
        endpoint={x=target.x,y=target.y,z=target.z,distance=distance,blocked=false}
    end
    return endpoint
end
function Lasers.forPlayer(player,cell)
    if API.Config.EnableLasers==false then return nil,"disabled" end
    local _,aiming=Access.call(player,"isAiming");if aiming~=true then return nil,"not aiming" end
    local _,weapon=Access.call(player,"getPrimaryHandItem")
    local _,part=Access.call(weapon,"getWeaponPart","Canon")
    local profile=Lasers.profiles[Access.fullType(part)]
    if not profile then return nil,"no registered laser" end
    local _,vector=Access.call(player,"getAimVector",Vector2 and Vector2.new and Vector2.new() or nil)
    local _,dx=Access.call(vector,"getX");local _,dy=Access.call(vector,"getY")
    if not Direction.fromVector(dx,dy) then return nil,"unknown aim" end
    local _,x=Access.call(player,"getX");local _,y=Access.call(player,"getY");local _,z=Access.call(player,"getZ")
    local source={x=x,y=y,z=z}
    local scale=API.Config.LaserRangeMultiplier or 1
    local endpoint,reason=Lasers.trace(cell,source,dx,dy,math.min(Lasers.MAX_RANGE,profile.range*scale))
    if not endpoint then return nil,reason end
    return {source=source,endpoint=endpoint,color={r=profile.color.r,g=profile.color.g,b=profile.color.b},owner=player}
end
Lasers.register{item="Base.Laser",range=16,color={r=1,g=0,b=0}}
API.Lasers=Lasers
return Lasers
