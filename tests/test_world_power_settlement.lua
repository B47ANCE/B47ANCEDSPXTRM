local hours=20;getGameTime=function()return{getWorldAgeHours=function()return hours end}end
isClient=function()return false end
local billed=0;local fail=false
powerWorks={getConsumerEnergyRatePerHour=function()return 2 end,
    consumeEnergy=function(_,amount)if fail then return false,"temporary failure"end;billed=billed+amount;return true,100-billed end,
    getConsumerPowerState=function()return{known=true,powered=true}end}
lightWorks={powerWorks=powerWorks,supportsWorldEmission=function()return true end}
package.loaded["lightWorks/lightWorks_API"]=lightWorks
local WorldPower=require "lightWorks/lightWorks_WorldPower"
local function item()
    return{data={lightWorksWorldEmitter={schemaVersion=1,active=true,lastPowerUpdateHours=20,processedOperations={}}},
        getModData=function(self)return self.data end,setActivated=function(self,v)self.active=v end,syncItemFields=function()end}
end
local light=item();hours=21
assert(WorldPower.setActive(light,false,"off"))
assert(billed==2 and light.data.lightWorksWorldEmitter.lastPowerUpdateHours==21,"switch-off must settle the preceding active hour")
assert(not WorldPower.setActive(light,false,"off")and billed==2,"replay must not debit twice")
hours=22;assert(WorldPower.setActive(light,true,"on")and billed==2,"inactive time must not be charged")

local failed=item();fail=true;hours=21
assert(not WorldPower.updateItem(failed,hours))
assert(failed.data.lightWorksWorldEmitter.lastPowerUpdateHours==20,"failed billing must retain its checkpoint")
assert(not WorldPower.setActive(failed,false,"failed-off")and failed.data.lightWorksWorldEmitter.active==true,
    "an unsettled transition must not erase debt or commit an operation")
fail=false;hours=21.5;local before=billed
assert(WorldPower.updateItem(failed,hours)and billed-before==3,"retry must charge the full unpaid interval exactly once")
assert(WorldPower.updateItem(failed,hours)and billed-before==3,"reconciliation at the same time must be idempotent")
assert(WorldPower.setActive(failed,false,"failed-off"),"the rejected operation must remain retryable")
local depleted=item();depleted.getID=function()return 55 end
depleted.getWorldItem=function()return{getX=function()return 3.5 end,getY=function()return 4.5 end,getZ=function()return 0 end}end
local packet;isServer=function()return true end
sendServerCommand=function(module,command,args)packet={module=module,command=command,args=args}end
powerWorks.getConsumerPowerState=function()return{known=true,powered=false}end
depleted.syncItemFields=function(self)assert(self.active==false,"native field sync must observe the final depleted state")end
assert(WorldPower.updateItem(depleted,20.25))
assert(packet and packet.command=="worldEmitterState"and packet.args.itemId==55 and packet.args.active==false,
    "depletion must reuse the world semantic-state message so existing clients clear their active flag")
print("lightWorks world-power settlement and retry checkpoint checks passed")
