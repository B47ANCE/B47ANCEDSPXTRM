ISBaseTimedAction={}
function ISBaseTimedAction:derive()local cls={};cls.__index=cls;setmetatable(cls,{__index=self});return cls end
function ISBaseTimedAction:new(character)return setmetatable({character=character},{__index=self})end
function ISBaseTimedAction:perform()end
package.loaded["TimedActions/ISBaseTimedAction"]=true
luautils={walkAdj=function()return true end};package.loaded["luautils"]=luautils
ISTimedActionQueue={add=function(action)ISTimedActionQueue.last=action end}
local fillHandler,serverHandler
Events={OnFillWorldObjectContextMenu={Add=function(fn)fillHandler=fn end},OnServerCommand={Add=function(fn)serverHandler=fn end}}
local ensured
package.loaded["lightWorks/lightWorks_WorldEmitterManager"]={ensure=function(backing,active,orientation)ensured={backing=backing,active=active,orientation=orientation}end}
powerWorks={getConsumerPowerState=function()return{known=true,powered=true}end}
local direct
package.loaded["lightWorks/lightWorks_WorldPower"]={setActive=function(item,active)direct={item=item,active=active};return true end}
lightWorks={powerWorks=powerWorks,supportsWorldEmission=function()return true end,
    getLightProfile=function()return{emitter={cone=true}}end}
package.loaded["lightWorks/lightWorks_API"]=lightWorks
local item={data={lightWorksWorldEmitter={schemaVersion=1,active=false}}}
function item:getID()return 42 end;function item:getDisplayName()return"Test Lamp"end;function item:getModData()return self.data end
local backing={getItem=function()return item end,getSquare=function()return{}end,getX=function()return 5 end,getY=function()return 6 end,getZ=function()return 0 end}
local options={};local context={addOption=function(_,label,...)local option={label=label,args={...}};options[#options+1]=option;return option end,
    addSubMenu=function(_,option,sub)option.sub=sub end}
ISContextMenu={getNew=function()return{options={},addOption=function(self,label,...)local option={label=label,args={...}};self.options[#self.options+1]=option;return option end}end}
local Menu=require "lightWorks/lightWorks_WorldEmitterMenu"
assert(fillHandler and serverHandler,"world menu and replication handlers must register")
Menu.addMenu(0,context,{backing},false)
assert(#options==2 and options[1].label=="Turn On Test Lamp"and not options[1].notAvailable,"charged inactive lights must offer Turn On")
assert(options[2].label=="Aim Test Lamp"and options[2].sub and #options[2].sub.options==4,"directional world lights must expose four deliberate aim choices")
Menu.onServerCommand("lightWorks","worldEmitterState",{x=5,y=6,z=0,itemId=42,active=true})
assert(item.data.lightWorksWorldEmitter.active==false,"missing game cell must make remote state fail closed")
getCell=function()return{getGridSquare=function()return{getWorldObjects=function()return{size=function()return 1 end,get=function()return backing end}end}end}end
Menu.onServerCommand("lightWorks","worldEmitterState",{x=5,y=6,z=0,itemId=42,active=true})
assert(item.data.lightWorksWorldEmitter.active==true and ensured and ensured.backing==backing and ensured.active==true,
    "replicated state must update the exact item and renderer binding")
Menu.onServerCommand("lightWorks","worldEmitterOrientation",{x=5,y=6,z=0,itemId=42,orientation="S"})
assert(item.data.lightWorksWorldEmitter.orientation=="S"and ensured.orientation=="S",
    "replicated orientation must update the exact item and renderer semantics")
print("lightWorks nil-safe world-emitter menu and replication checks passed")
local serial=0
getRandomUUID=function()serial=serial+1;return string.format("00000000-0000-4000-8000-%012d",serial)end
isClient=function()return true end
local actor={getX=function()return 5 end,getY=function()return 6 end}
local requests={};sendClientCommand=function(_,_,command,args)requests[#requests+1]={command=command,args=args}end
package.loaded["lightWorks/lightWorks_WorldEmitterMenu"]=nil
local clientA=require "lightWorks/lightWorks_WorldEmitterMenu"
clientA.Action:new(actor,backing,item,false):perform()
package.loaded["lightWorks/lightWorks_WorldEmitterMenu"]=nil
local clientB=require "lightWorks/lightWorks_WorldEmitterMenu"
clientB.Action:new(actor,backing,item,false):perform()
clientB.OrientationAction:new(actor,backing,item,"E"):perform()
assert(#requests==3 and requests[1].args.operationId~=requests[2].args.operationId
    and requests[2].args.operationId~=requests[3].args.operationId,"world controls must generate distinct IDs across clients and action types")
getRandomUUID=nil;clientB.Action:new(actor,backing,item,false):perform()
assert(#requests==3,"UUID failure cannot submit an invalid or colliding world request")
