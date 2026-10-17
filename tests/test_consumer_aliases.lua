local API=require "lightWorks/lightWorks_API"
local Migration=require "lightWorks/lightWorks_LegacyMigration"
local C=require "lightWorks/lightWorks_ConsumerIntegrations"
assert(not C.refreshNightfall() and next(Migration.aliases)==nil)
API.registerBulb{item="ProjectNightfall.LightBulbUV",tags={PROJECT_NIGHTFALL=true}}
assert(next(Migration.aliases)==nil,"both targets must exist before either alias is published")
API.registerBulb{item="ProjectNightfall.LightBulbUVHighOutput",tags={PROJECT_NIGHTFALL=true}}
assert(C.refreshNightfall() and C.aliasContract().status=="AVAILABLE")
local contract=C.aliasContract();contract.aliases["ProjectNightfall.UVBulb"]="wrong"
assert(C.aliasContract().aliases["ProjectNightfall.UVBulb"]=="ProjectNightfall.LightBulbUV")
API.registerLight{item="Test.Light",tools=false}
getActivatedMods=function()return {size=function()return 0 end}end
for old,current in pairs(C.aliasContract().aliases) do
    for _,burned in ipairs({false,true}) do
        local legacy={hasExplicitBulbState=true,installedBulb=old,burnMinutes=37,burnedOut=burned}
        if burned then legacy.lastBurnedBulbType=old;legacy.installedBulb=nil end
        local data={Bulbworks=legacy}
        local light={getFullType=function()return "Test.Light"end,getModData=function()return data end,
            getID=function()return 42 end,transmitModData=function()end,syncItemFields=function()end}
        assert(Migration.process(light))
        assert(data.Bulbworks==legacy and data.lightWorks.burnMinutes==37 and data.lightWorks.burnedOut==burned)
        assert((burned and data.lightWorks.lastBurnedBulbType or data.lightWorks.installedBulb)==current)
        assert(Migration.process(light),"migration receipts must survive repeated calls")
    end
end
Migration.aliases["ProjectNightfall.HighOutputUVBulb"]={item="Other.Bulb",owner="other"}
Migration.aliases["ProjectNightfall.UVBulb"]=nil
assert(not C.refreshNightfall() and not Migration.aliases["ProjectNightfall.UVBulb"],"conflicts cannot partially register")
Migration.aliases={}; -- production registry retains its original table; reset it explicitly below.
package.loaded["lightWorks/lightWorks_LegacyMigration"].aliases=Migration.aliases
for i=1,63 do Migration.aliases["Test."..i]={item="Other.Bulb",owner="fixture"} end
assert(not C.refreshNightfall() and C.aliasContract().status=="CAPACITY_BLOCKED")
print("Nightfall stored-field aliases, late registration, wear, burnout and atomic refusal pass")
