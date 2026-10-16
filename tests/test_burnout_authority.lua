local API=require "lightWorks/lightWorks_API"
API.registerBulb{item="Test.WearBulb",burnout={lifetimeMinutes=1}}
API.registerLight{item="Test.WearLight",defaultBulb="Test.WearBulb"}
local item={data={}}
function item:getFullType()return "Test.WearLight"end
function item:getModData()return self.data end
function item:isActivated()return true end
isClient=function()return true end;isServer=function()return false end
assert(API.updateBulbBurnout(item,2)==false and API.hasBulb(item),"clients must not progress or remove bulbs")
assert(API.burnOutBulb(item)==false and API.setBulbBurnMinutes(item,99)==false,"direct burnout mutations require authority")

isClient=function()return false end;isServer=function()return true end
local tick;Events={OnTick={Add=function(fn)assert(not tick);tick=fn end}}
local hours=10;getGameTime=function()return{getWorldAgeHours=function()return hours end}end
local player={};getOnlinePlayers=function()return{size=function()return 1 end,get=function()return player end}end
getSpecificPlayer=function()error("dedicated processing must not require local players")end
API.collectPlayerLights=function(got)assert(got==player);return{item,item}end
local access=require "lightWorks/lightWorks_ItemAccess"
local added,synced=0,0
access.findWeaponForPart=function()return nil end
access.addItem=function(got,kind)assert(got==player and kind==API.Config.BurnedBulbItem);added=added+1;return{}end
access.syncServiceState=function(got,target)assert(got==player and target==item);synced=synced+1;return true end
local Burnout=require "lightWorks/lightWorks_BurnoutAuthority"
assert(tick==Burnout.onTick,"authority loop must register once")
assert(dofile("src/lightWorks/42/media/lua/shared/lightWorks/lightWorks_BurnoutAuthority.lua")==Burnout,
    "duplicate shared/client loads must reuse one authority loop")
tick();hours=hours+2/60;tick()
assert(not API.hasBulb(item)and added==1 and synced==1,"dedicated burnout must mutate, award and sync once")
hours=hours+2/60;tick();assert(added==1,"already burned bulbs cannot award duplicate items")
isClient=function()return true end;isServer=function()return false end
hours=hours+1;tick();assert(added==1,"client ticks cannot award inventory output")
isClient=function()return false end;isServer=function()return false end
getOnlinePlayers=function()return{size=function()return 0 end}end
getSpecificPlayer=function(index)return index==0 and player or nil end
assert(API.installBulb(item,"Test.WearBulb"))
hours=hours+2/60;tick()
assert(added==2,"SP must progress local lights even when the online-player collection is empty")
print("lightWorks dedicated-authority burnout and duplicate-item checks passed")
