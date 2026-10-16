local handler;Events={OnClientCommand={Add=function(fn)handler=fn end}}
local item={data={}}
function item:getID()return 77 end
function item:getModData()return self.data end
function item:transmitModData()self.transmitted=(self.transmitted or 0)+1 end
local backing={getItem=function()return item end}
local objects={size=function()return 1 end,get=function(_,index)return index==0 and backing or nil end}
local square={getWorldObjects=function()return objects end}
getCell=function()return{getGridSquare=function(_,x,y,z)if x==10 and y==20 and z==0 then return square end end}end
local broadcasts={}
sendServerCommand=function(module,command,args)broadcasts[#broadcasts+1]={module=module,command=command,args=args}end
lightWorks={supportsWorldEmission=function(got)return got==item end,
    getLightProfile=function(got)return got==item and{emitter={cone=true}}or nil end}
package.loaded["lightWorks/lightWorks_API"]=lightWorks
local mutations={}
package.loaded["lightWorks/lightWorks_WorldPower"]={setActive=function(got,active,operationId)
    mutations[#mutations+1]={item=got,active=active,operationId=operationId};return true,{active=active,operationId=operationId}
end,prepareBacking=function(gotBacking,gotItem)assert(gotBacking==backing and gotItem==item);mutations.prepared=true end}
local player={getX=function()return 11 end,getY=function()return 20 end,getZ=function()return 0 end}
local Server=require "lightWorks/lightWorks_WorldEmitterServer"
assert(handler==Server.onCommand,"server command handler must register exactly once")
Server.onCommand("lightWorks","setWorldEmitterActive",player,{x=10,y=20,z=0,itemId=77,active=true,operationId="op-1"})
assert(#mutations==1 and mutations[1].item==item and mutations[1].active==true,"server must resolve one exact nearby world item")
assert(mutations.prepared,"server must prepare the accepted physical backing")
assert(#broadcasts==1 and broadcasts[1].command=="worldEmitterState"and broadcasts[1].args.itemId==77,"accepted state must replicate")
player.getX=function()return 30 end
Server.onCommand("lightWorks","setWorldEmitterActive",player,{x=10,y=20,z=0,itemId=77,active=false,operationId="far"})
assert(#mutations==1,"remote world-light mutations must be rejected")
player.getX=function()return 11 end
Server.onCommand("lightWorks","setWorldEmitterActive",player,{x=10,y=20,z=0,itemId=78,active=false,operationId="stale"})
Server.onCommand("lightWorks","setWorldEmitterActive",player,{x=10.5,y=20,z=0,itemId=77,active=false,operationId="fractional"})
assert(#mutations==1,"stale and malformed identities must fail closed")
Server.onCommand("lightWorks","setWorldEmitterOrientation",player,{x=10,y=20,z=0,itemId=77,orientation="W",operationId="aim-1"})
assert(item.data.lightWorksWorldEmitter.orientation=="W"and item.transmitted==1,"server must persist a valid nearby cone orientation")
assert(#broadcasts==2 and broadcasts[2].command=="worldEmitterOrientation"and broadcasts[2].args.orientation=="W",
    "accepted orientation must replicate")
Server.onCommand("lightWorks","setWorldEmitterOrientation",player,{x=10,y=20,z=0,itemId=77,orientation="UP",operationId="aim-bad"})
assert(item.data.lightWorksWorldEmitter.orientation=="W"and #broadcasts==2,"invalid orientation must fail closed")
print("lightWorks authoritative world-emitter command checks passed")

Server.onCommand("lightWorks","setWorldEmitterOrientation",player,{x=10,y=20,z=0,itemId=77,orientation=27.5,operationId="angle-1"})
assert(item.data.lightWorksWorldEmitter.orientation==27.5 and #broadcasts==3)
Server.onCommand("lightWorks","setWorldEmitterOrientation",player,{x=10,y=20,z=0,itemId=77,orientation=180,operationId="angle-1"})
assert(item.data.lightWorksWorldEmitter.orientation==27.5 and #broadcasts==3,"orientation replays must not mutate")
local future={schemaVersion=99};item.data.lightWorksWorldEmitter=future
Server.onCommand("lightWorks","setWorldEmitterOrientation",player,{x=10,y=20,z=0,itemId=77,orientation=180,operationId="future"})
assert(item.data.lightWorksWorldEmitter==future and #broadcasts==3,"future state must be retained")
