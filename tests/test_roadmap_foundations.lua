local Sandbox=require "lightWorks/lightWorks_Sandbox"
local values=Sandbox.read({EnableSunburn="true",SunburnDoseMultiplier=0/0,
    LowBatteryFlickerPeriodMs=999999,SunburnFirstDegreeDoseHours=24,SunburnMaximumDoseHours=.2,
    LowBatteryFlickerMinimumOffFraction=.8,LowBatteryFlickerMaximumOffFraction=.1})
assert(values.EnableSunburn==true and values.SunburnDoseMultiplier==1)
assert(values.LowBatteryFlickerPeriodMs==15000 and values.SunburnMaximumDoseHours>24)
assert(values.LowBatteryFlickerMaximumOffFraction==.8)
local Direction=require "lightWorks/lightWorks_Direction"
assert(Direction.normalize(360)==nil and Direction.normalize(0/0)==nil and Direction.normalize("UP")==nil)
local x,y=Direction.vector(90);assert(math.abs(x-1)<.00001 and math.abs(y)<.00001)
for _,angle in ipairs({0,27.5,90,180,270,359}) do
    local dx,dy=Direction.vector(angle)
    assert(math.abs(Direction.fromVector(dx,dy)-angle)<.00001)
end
local function player(x) return {getX=function()return x end,getY=function()return 0 end,getZ=function()return 0 end} end
local localPlayer,remote,far=player(0),player(10),player(100)
getSpecificPlayer=function(i)if i==0 then return localPlayer end end
getOnlinePlayers=function()return {size=function()return 3 end,get=function(_,i)return ({localPlayer,remote,far})[i+1]end}end
local Players=require "lightWorks/lightWorks_Players"
assert(#Players.collect(true)==2 and #Players.collect(false)==3,"remote rendering must be nearby and deduplicated")
getOnlinePlayers=function()return {size=function()return 0 end}end
assert(#Players.collect(false)==1,"SP must not disappear when online collection is empty")
isServer=function()return true end
getSpecificPlayer=function()error("dedicated must never require local slots")end
assert(#Players.collect(false)==0)
print("sandbox validation, free angles and bounded player discovery pass")
