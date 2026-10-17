Events={EveryTenMinutes={Add=function()end}}
getGameTime=function()return{getWorldAgeHours=function()return 12 end}end
isClient=function()return false end
local consumed=0;local powered=true
powerWorks={
    getConsumerEnergyRatePerHour=function()return 2 end,
    consumeEnergy=function(_,amount)consumed=consumed+amount;return true,10-consumed end,
    getConsumerPowerState=function()return{known=true,powered=powered}end,
}
lightWorks={powerWorks=powerWorks,supportsWorldEmission=function()return true end}
package.loaded["lightWorks/lightWorks_API"]=lightWorks
local item={data={lightWorksWorldEmitter={schemaVersion=1,active=true,lastPowerUpdateHours=10}}}
function item:getModData()return self.data end
function item:syncItemFields()self.synced=(self.synced or 0)+1 end
function item:setActivated(value)self.nativeActive=value end
local WorldPower=require "lightWorks/lightWorks_WorldPower"
local ok,amount=WorldPower.updateItem(item,10.5)
assert(ok and amount==1 and consumed==1,"world light must consume elapsed absolute energy")
assert(item.data.lightWorksWorldEmitter.lastPowerUpdateHours==10.5 and item.synced==1,"world drain must checkpoint and synchronize")
powered=false
assert(WorldPower.updateItem(item,11))
assert(item.data.lightWorksWorldEmitter.active==false and item.nativeActive==false,"depletion must disable visible and UV world emission")
local before=consumed
assert(WorldPower.updateItem(item,12)and consumed==before,"inactive world lights must not consume catch-up energy")
powered=true
local toggled,result=WorldPower.setActive(item,true,"toggle-1")
assert(toggled and result.active==true and item.data.lightWorksWorldEmitter.active==true,"authority must activate a charged world light")
assert(WorldPower.setActive(item,true,"toggle-1")==false,"world activation operations must be replay-safe")
powered=false
assert(WorldPower.setActive(item,true,"toggle-empty")==false,"empty world lights must fail closed")
local backing={setMovedThumpable=function(self,value)self.moved=value end}
powered=true;item.data.lightWorksWorldEmitter.active=true
assert(WorldPower.prepareBacking(backing,item)and backing.moved==true,"server must prepare active world lights as physical thump targets")
powered=false
assert(WorldPower.prepareBacking(backing,item)and backing.moved==false,"unpowered lights must withdraw physical defense targeting")
print("lightWorks authoritative elapsed world-power checks passed")

lightWorks.hasBulb=function()return false end
local target={setMovedThumpable=function(self,v)self.attackable=v end}
assert(WorldPower.prepareBacking(target,item) and target.attackable==false,"server cannot expose a bulbless physical target")
lightWorks.hasBulb=function()return true end;powered=true
item.data.lightWorksWorldEmitter.active=true
assert(WorldPower.prepareBacking(target,item) and target.attackable==true)
target.getThumpCondition=function()return 0 end
assert(WorldPower.prepareBacking(target,item) and target.attackable==false,"destroyed backings must be withdrawn")

lightWorks.Config={EnableWorldEmitters=false}
local beforeDisable=consumed
assert(WorldPower.updateItem(item,15) and consumed==beforeDisable and item.data.lightWorksWorldEmitter.lastPowerUpdateHours==15)
assert(not WorldPower.setActive(item,true,"disabled-on"))
assert(WorldPower.prepareBacking(target,item) and target.attackable==false)
assert(WorldPower.updateItem(item,14) and item.data.lightWorksWorldEmitter.lastPowerUpdateHours==15,"disabled time cannot rewind checkpoints")
