lightWorks=nil;dofile(arg[1]);local API=lightWorks;API.registerLight{item="Test.ServerPattern",tools=false}
package.loaded["lightWorks/lightWorks_API"]=API;local Access=dofile(arg[2]);package.loaded["lightWorks/lightWorks_ItemAccess"]=Access;package.loaded["lightWorks/lightWorks_Patterns"]=dofile(arg[3])
local itemData={};local item={getID=function()return 9 end,getFullType=function()return"Test.ServerPattern"end,getModData=function()return itemData end,getContainer=function()return{}end}
local list={iterator=function()local used=false;return{hasNext=function()return not used end,next=function()used=true;return item end}end}
local inventory={getItems=function()return list end};local player={getInventory=function()return inventory end,getAttachedItems=function()return{iterator=function()return{hasNext=function()return false end}end}end}
local registered;Events={OnClientCommand={Add=function(fn)registered=fn end}}
syncItemModData=function()end;syncItemFields=function()end;syncItemActivated=function()end
local Server=dofile(arg[4]);assert(registered==Server.onCommand and Server.resolve(player,9)==item)
Server.onCommand("lightWorks","setPattern",player,{itemId=9,patternId="beacon",operationId="server-1"})
assert(API.Patterns.getPatternId(item)=="beacon")
Server.onCommand("lightWorks","setPattern",player,{itemId=999,patternId="pulse",operationId="server-2"});assert(API.Patterns.getPatternId(item)=="beacon")
Server.onCommand("lightWorks","setPattern",player,{itemId=9,patternId="missing",operationId="server-3"});assert(API.Patterns.getPatternId(item)=="beacon")
print("lightWorks authoritative owned-item pattern command checks passed")
