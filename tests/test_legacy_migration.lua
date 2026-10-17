local API=require "lightWorks/lightWorks_API"
API.registerBulb{item="Base.LightBulb"}
API.registerLight{item="Test.Light",defaultBulb="Base.LightBulb",tools=false}
local Migration=require "lightWorks/lightWorks_LegacyMigration"
local function item(legacy,current)
    return {data={Bulbworks=legacy,lightWorks=current},getFullType=function()return "Test.Light"end,
        getID=function()return 42 end,getModData=function(self)return self.data end,
        transmitModData=function(self)self.transmits=(self.transmits or 0)+1 end,syncItemFields=function()end}
end
getActivatedMods=function()return {size=function()return 0 end}end
next=nil -- production Kahlua compatibility, including migration emptiness checks.
local old={hasExplicitBulbState=true,installedBulb="Base.LightBulb",burnMinutes=12,burnedOut=false}
local a=item(old);assert(API.getInstalledBulbType(a)==nil,"unmigrated legacy must not silently become a default bulb")
assert(Migration.process(a));assert(a.data.lightWorks.burnMinutes==12 and a.data.Bulbworks==old)
assert(a.transmits==1 and not Migration.isBlocked(a))
assert(Migration.process(a) and a.transmits==1,"receipt must prevent replay after save/reload")
local reload=item(old,a.data.lightWorks);reload.data.lightWorksLegacyMigration=a.data.lightWorksLegacyMigration
assert(Migration.process(reload) and not reload.transmits)
local empty=item({hasExplicitBulbState=true,burnedOut=false});assert(Migration.process(empty) and not API.hasBulb(empty))
local bad=item({burnMinutes=0/0});assert(not Migration.process(bad) and bad.data.lightWorks==nil)
assert(bad.data.lightWorksLegacyMigration.status=="quarantined" and bad.data.Bulbworks.burnMinutes~=bad.data.Bulbworks.burnMinutes)
local conflict=item(old,{burnMinutes=1});assert(not Migration.process(conflict) and conflict.data.lightWorks.burnMinutes==1)
local alias=item({hasExplicitBulbState=true,installedBulb="External.Old"})
assert(not Migration.process(alias) and alias.data.lightWorks==nil)
Migration.registerAlias("External.Old","Base.LightBulb","Explicit owner fixture")
assert(Migration.process(alias) and alias.data.lightWorks.installedBulb=="Base.LightBulb")
Bulbworks={};local dual=item(old);assert(not Migration.process(dual) and dual.data.lightWorks==nil);Bulbworks=nil
local malformed=item({baseColorRed=.5});assert(not Migration.process(malformed))
local unknown=item({schemaVersion=99});assert(not Migration.process(unknown))
isClient=function()return true end
local client=item(old);assert(not Migration.process(client) and not client.data.lightWorksLegacyMigration)
print("one-way migration, replay, unknown retention and authority pass")
