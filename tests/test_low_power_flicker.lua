local lightWorks={Config={EnableLowBatteryFlicker=true,LowBatteryFlickerThreshold=.1,
    LowBatteryFlickerPeriodMs=4000,LowBatteryFlickerMinimumOffFraction=.1,LowBatteryFlickerMaximumOffFraction=.6}}
package.loaded["lightWorks/lightWorks_API"]=lightWorks
local charge=.5;local powered=true;local known=true
powerWorks={getConsumerPowerState=function()return{known=known,powered=powered,chargeFraction=charge}end}
local Flicker=dofile(arg[1])
local item={getID=function()return 42 end,getFullType=function()return"Test.WeaponLight"end}

local visible,state=Flicker.shouldRender(item,0)
assert(visible and state.known and not state.flickering,"healthy cells must emit continuously")
charge=.05
local sawOn,sawOff=false,false
for time=0,8000,100 do local on,s=Flicker.shouldRender(item,time);sawOn=sawOn or on;sawOff=sawOff or not on;assert(s.flickering)end
assert(sawOn and sawOff,"low cells must have deterministic on and off windows")
local first=Flicker.getState(item,1234);local second=Flicker.getState(item,1234)
assert(first.visible==second.visible and first.offFraction==second.offFraction,"same item/time must not reroll per frame")
powered=false;assert(not Flicker.shouldRender(item,1234),"known empty consumers must not render")
known=false;local unknown=Flicker.getState(item,1234);assert(unknown.visible and not unknown.flickering,"unknown power state must not invent flicker")
lightWorks.Config.EnableLowBatteryFlicker=false;assert(Flicker.shouldRender(item,1234),"sandbox disable must preserve normal rendering")
print("lightWorks deterministic powerWorks-backed low-battery flicker checks passed")

lightWorks.Config.EnableLowBatteryFlicker=true;known=true;powered=true;charge=.05
local milliseconds=100
getTimestampMs=function()return milliseconds end
getGameTime=function()error("flicker must not use accelerated game time")end
assert(Flicker.getState(item).visible==Flicker.getState(item,milliseconds).visible)
milliseconds=2200
assert(Flicker.getState(item).visible==Flicker.getState(item,milliseconds).visible)
B47ANCEDPower={getConsumerPowerState=function()return {known=true,powered=false,chargeFraction=0}end}
assert(not Flicker.shouldRender(item),"maintained power namespace must take precedence")
