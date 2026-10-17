package.preload["TimedActions/ISBaseTimedAction"]=function()
    ISBaseTimedAction={derive=function(self)local c={};c.__index=c;setmetatable(c,{__index=self});return c end,
        new=function(self,actor)return setmetatable({character=actor},{__index=self})end,perform=function()end}
    return true
end
local API=require "lightWorks/lightWorks_API"
local C=require "lightWorks/lightWorks_ConsumerIntegrations"
local E=require "lightWorks/lightWorks_ConsumerExposure"
local complete,calls=true,0
C.inspectWaterTreatment=function()return complete end
C.treatWater=function(_,op)assert(op:find("LW-WATER-",1,true)==1);calls=calls+1;return true end
getRandomUUID=function()return "12345678-1234-1234-1234-123456789abc" end
local W=require "lightWorks/lightWorks_WaterTreatmentAction"
local actor={isDead=function()return false end,getX=function()return 1 end,getY=function()return 1 end,getZ=function()return 0 end}
local owner={getSquare=function()return {} end,getObjectIndex=function()return 1 end}
E.position=function()return {x=1,y=2,z=0}end
local a=W.Action:new(actor,owner);assert(a:getDuration()==1500 and a:isValid())
isClient=function()return true end;assert(not a:complete() and calls==0 and not a.completed)
isClient=function()return false end;assert(a:complete() and calls==1)
assert(not a:complete() and calls==1)
local b=W.Action:new(actor,owner);complete=false
assert(not b:complete() and calls==1,"lost UVC/power after action start must reject")
complete=true;actor.getX=function()return 100 end
assert(not W.Action:new(actor,owner):complete() and calls==1)
actor.getX=function()return 1 end;owner.getObjectIndex=function()return -1 end
assert(not W.Action:new(actor,owner):complete() and calls==1,"removed target cannot be treated")
print("native timed UVC treatment validates authority, placement, reach, completion exposure and duplicate callbacks")
