local API=require "lightWorks/lightWorks_API"
API.registerBulb{item="Test.DropBulb"};API.registerLight{item="Test.DropLight",defaultBulb="Test.DropBulb"}
local hours=10;getGameTime=function()return{getWorldAgeHours=function()return hours end}end
isClient=function()return false end;isServer=function()return true end
local sent,originalCalls=0,0;local reject=false;local fail=false
local item={data={},active=true}
function item:getFullType()return "Test.DropLight"end
function item:getModData()return self.data end
function item:isActivated()return self.active end
function item:getWorldItem()return self.backing end
local backing={setMovedThumpable=function(self,v)self.attackable=v end}
powerWorks={getConsumerPowerState=function()return{known=true,powered=true}end}
ISDropWorldItemAction={complete=function(self)
    originalCalls=originalCalls+1
    if fail then error("native drop failed")end
    if reject then return false end
    item.backing=backing
    local state=item.data.lightWorksWorldEmitter
    sent=state and state.active==true and state.lastPowerUpdateHours==hours and sent+1 or sent
    return true
end}
package.loaded["TimedActions/ISDropWorldItemAction"]=true
-- Permit the pre-fix baseline to reach the behavioral assertion, not fail on a missing new file.
local file=io.open("src/lightWorks/42/media/lua/shared/lightWorks/lightWorks_WorldDrop.lua","r")
if file then file:close();require "lightWorks/lightWorks_WorldDrop"end
local action=setmetatable({item=item,character={getDir=function()return "E"end}},{__index=ISDropWorldItemAction})
assert(action:complete())
assert(sent==1 and item.data.lightWorksWorldEmitter.orientation=="E","server drop must initialize state before vanilla serializes the item")
assert(backing.attackable==true,"authoritative drop must prepare its physical backing")
assert(package.loaded["lightWorks/lightWorks_WorldEmitterManager"]==nil,"headless drop cannot load client rendering")
local first=ISDropWorldItemAction.complete
lightWorks.WorldDrop.install();assert(first==ISDropWorldItemAction.complete,"repeat install cannot double-wrap vanilla")
item.data.lightWorksWorldEmitter.id="LW-WORLD-legacy"
item.data.lightWorksWorldEmitter.processedOperations={"LW-WORLD-TOGGLE-77-1"}
hours=11;item.backing=nil;item.active=false;assert(action:complete())
assert(item.data.lightWorksWorldEmitter.active==false and item.data.lightWorksWorldEmitter.lastPowerUpdateHours==11,
    "re-drop must use current carried state and reset the world-only checkpoint")
assert(item.data.lightWorksWorldEmitter.id=="LW-WORLD-legacy"and item.data.lightWorksWorldEmitter.processedOperations[1]=="LW-WORLD-TOGGLE-77-1",
    "existing schema-1 durable identity and replay history must survive re-drop")
local originalState=item.data.lightWorksWorldEmitter
isClient=function()return true end;isServer=function()return false end
hours=12;item.active=true;assert(action:complete())
assert(item.data.lightWorksWorldEmitter==originalState and originalState.lastPowerUpdateHours==11,"client completion must not initialize authority state")
isClient=function()return false end;isServer=function()return true end
item.backing=nil;reject=true
assert(action:complete()==false and item.data.lightWorksWorldEmitter==originalState,"rejected native placement must restore the prior state reference")
reject=false;fail=true
local ok,errorText=pcall(action.complete,action)
assert(not ok and tostring(errorText):find("native drop failed",1,true)and item.data.lightWorksWorldEmitter==originalState,
    "failed placement must restore state and propagate the real error")
fail=false;item.data.lightWorksWorldEmitter={schemaVersion=99};local count=originalCalls
assert(action:complete()==false and originalCalls==count and item.data.lightWorksWorldEmitter.schemaVersion==99,
    "unknown future save state must be preserved and rejected before vanilla mutation")
local malformed={schemaVersion=1,processedOperations="corrupt"};item.data.lightWorksWorldEmitter=malformed
assert(action:complete()==false and originalCalls==count and item.data.lightWorksWorldEmitter==malformed,
    "malformed replay history cannot be silently reset to an empty list")
print("lightWorks shared drop initialization and idempotent hook checks passed")
