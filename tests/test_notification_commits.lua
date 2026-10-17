local API=require "lightWorks/lightWorks_API"
local N=require "lightWorks/lightWorks_Notifications"
API.registerBulb{item="Base.LightBulb"}
API.registerLight{item="Test.Light",emitter={cone=true},tools=false}
local item={data={},getFullType=function()return "Test.Light"end,getID=function()return 42 end,
    getModData=function(self)return self.data end,transmitModData=function()end}
local events={}
N.subscribe("*","commit-observer",function(e)events[#events+1]=e end)
local P=require "lightWorks/lightWorks_Patterns"
assert(P.set(item,"pulse","pattern-op") and #events==1 and events[1].topic=="pattern")
assert(not P.set(item,"pulse","pattern-op") and #events==1)
local Orientation=require "lightWorks/lightWorks_WorldOrientation"
assert(Orientation.set(item,45,"orientation-op") and events[2].topic=="orientation")
assert(not Orientation.set(item,45,"orientation-op") and #events==2)
isClient=function()return true end
assert(not P.set(item,"steady","client") and not Orientation.set(item,90,"client") and #events==2)
isClient=function()return false end
local Sunburn=require "lightWorks/lightWorks_Sunburn"
local patient={data={lightWorksSunburn={schemaVersion=1,dose=.5,severity=.2}},getModData=function(self)return self.data end,
    getOnlineID=function()return 7 end,transmitModData=function()end}
assert(Sunburn.getState(patient) and patient.data.lightWorksSunburn.processedOperations==nil,"read-only state query must preserve old records")
assert(Sunburn.applyTreatment(patient,.1,"treatment-op") and events[3].topic=="sunburn" and events[3].subject.id=="7")
assert(not Sunburn.applyTreatment(patient,.1,"treatment-op") and #events==3)
patient.data.lightWorksSunburn={schemaVersion=1,dose=.5,severity=.2,processedOperations=false}
assert(not Sunburn.getState(patient) and patient.data.lightWorksSunburn.processedOperations==false)
assert(not Sunburn.applyTreatment(patient,.1,"invalid") and #events==3)
local Migration=require "lightWorks/lightWorks_LegacyMigration"
getActivatedMods=function()return{size=function()return 0 end}end
item.data={Bulbworks={hasExplicitBulbState=true,installedBulb="Base.LightBulb",burnMinutes=5,burnedOut=false}}
assert(Migration.process(item) and events[4].topic=="migration")
assert(Migration.process(item) and #events==4,"idempotent receipt cannot republish")
print("events follow committed state; duplicate, client, malformed and read-only paths emit no false transitions")
