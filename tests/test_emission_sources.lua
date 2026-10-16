lightWorks={Bulbs={},Lights={},Config={EnableLightPatterns=true,EnableLowBatteryFlicker=false}}
local lamp={active=true,powered=true,getBulbItem=function()return "Test.Bulb"end,isActivated=function(self)return self.active end,
    getX=function()return 5 end,getY=function()return 5 end,getZ=function()return 0 end,
    getModData=function()return {lightWorksWorldEmitter={orientation="E"}}end,
    getThumpableFor=function(self)return self end,Thump=function(self,pawn,count)self.thumped=(self.thumped or 0)+count end}
lightWorks.Bulbs["Test.Bulb"]={emissions={UV={intensity=1}}}
lightWorks.getBulbProfile=function(t)return lightWorks.Bulbs[t]end
lightWorks.getLightProfile=function()return {emitter={range=9,strength=.7,cone=false}}end
lightWorks.isRegisteredLight=function()return true end
lightWorks.getEmissionProfile=function()return lightWorks.Bulbs["Test.Bulb"].emissions end
lightWorks.isBulbBurnedOut=function()return false end
powerWorks={isRegisteredConsumer=function()return true end,getConsumerPowerState=function(item)return {known=true,powered=item.powered}end}
package.loaded["lightWorks/lightWorks_API"]=lightWorks
local Sources=require "lightWorks/lightWorks_EmissionSources"
local source=assert(Sources.inspect(lamp))
assert(source.emitting and source.channels.visible and source.channels.UV and source.range==9)
assert(source.destroy.supported and Sources.requestPhysicalAttack(source,{}) and lamp.thumped==1,
    "verified world lights should use the engine Thump contract")
lamp.active=false;assert(Sources.inspect(lamp)==nil,"inactive fixtures must fail closed")
lamp.active=true;lamp.powered=false;assert(Sources.inspect(lamp)==nil,"unpowered fixtures must fail closed")
lamp.powered=true
local list={size=function()return 1 end,get=function()return lamp end}
local dropped={moved=true,getItem=function()return lamp end,getX=function()return 5.5 end,getY=function()return 5.5 end,getZ=function()return 0 end,
    getThumpableFor=function(self)return self.moved and self or nil end,Thump=function(self,pawn,count)self.thumped=(self.thumped or 0)+count end}
local worldList={size=function()return 1 end,get=function()return dropped end}
local square={getObjects=function()return list end,getWorldObjects=function()return worldList end}
getCell=function()return {getGridSquare=function(_,x,y,z)if x==5 and y==5 and z==0 then return square end end}end
local collected=Sources.collectWorld(lamp,2,8)
assert(#collected==2,"fixtures and dropped world inventory items must both be collected")
local droppedSource=assert(Sources.inspect(dropped))
assert(droppedSource.object==dropped and droppedSource.backingItem==lamp,"physical backing and item authority must remain separate")
assert(droppedSource.directionX==1 and droppedSource.directionY==0,"persisted placement orientation must drive directional semantics")
assert(droppedSource.destroy.supported and Sources.requestPhysicalAttack(droppedSource,{})and dropped.thumped==1,
    "prepared dropped lights must expose their physical backing to Nightfall attacks")
local UV=require "lightWorks/lightWorks_UV"
local uvSources=UV.collectWorldEmitters(lamp,2)
assert(#uvSources==2,"Nightfall-facing UV collection must include fixtures and dropped inventory lights")
local directional
for _,entry in ipairs(uvSources)do if entry.owner==dropped then directional=entry end end
assert(directional and directional.intensity==1 and directional.directionX==1,
    "dropped UV must retain UV strength and placement direction")
Sources.registerProvider{id="broken",priority=200,inspect=function()error("bad provider")end}
assert(Sources.inspect(lamp),"one broken provider must not suppress later providers")
print("lightWorks active emission-source contract checks passed")
