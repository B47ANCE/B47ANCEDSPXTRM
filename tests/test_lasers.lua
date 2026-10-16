local API=require "lightWorks/lightWorks_API"
local Lasers=require "lightWorks/lightWorks_Lasers"
local wall=4;local unloaded=false
local cell={getGridSquare=function(_,x,y,z)
    if unloaded and x>=2 then return nil end
    return {testVisionAdjacent=function(_,dx,dy)return x<wall and x+dx>=wall and "Blocked" or "Clear" end}
end}
local ray=assert(Lasers.trace(cell,{x=.5,y=.5,z=0},1,0,10))
assert(ray.blocked and ray.x<4 and ray.distance>3,"laser must stop before thin walls")
unloaded=true;assert(Lasers.trace(cell,{x=.5,y=.5,z=0},1,0,10)==nil,"unknown paths must not reveal geometry")
unloaded=false;wall=100
assert(math.abs(Lasers.trace(cell,{x=.5,y=.5,z=0},1,1,5).distance-5)<.00001)
assert(not pcall(Lasers.register,{item="Bad",range=math.huge}))
Vector2={new=function()return {}end}
local part={getFullType=function()return "Base.Laser"end}
local weapon={getWeaponPart=function(_,slot)assert(slot=="Canon");return part end}
local player={isAiming=function()return true end,getPrimaryHandItem=function()return weapon end,
    getAimVector=function()return {getX=function()return 1 end,getY=function()return 0 end}end,
    getX=function()return .5 end,getY=function()return .5 end,getZ=function()return 0 end}
assert(Lasers.forPlayer(player,cell).endpoint.distance==16)
API.Config.EnableLasers=false;assert(Lasers.forPlayer(player,cell)==nil)
print("laser registration, aiming, range and obstruction pass")
