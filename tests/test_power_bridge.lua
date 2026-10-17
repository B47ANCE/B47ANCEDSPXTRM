local API=require "lightWorks/lightWorks_API"
API.registerLight{item="Test.PowerLight",power={sizes={"AA"},nominalCellCount=2}}
local registered={}
local canonical={registerConsumer=function(profile)registered[profile.item]=profile end,
    getConsumerPowerState=function()end,refreshConsumer=function()end,
    getConsumerEnergyRatePerHour=function()end,consumeEnergy=function()end}
package.preload["B47ANCEDPower/Definitions"]=function()B47ANCEDPower=canonical;return canonical end
powerWorks={registerConsumer=function()error("legacy provider must not shadow maintained dependency")end}
require "lightWorks/lightWorks_powerWorks"
assert(API.powerWorks==canonical and registered["Test.PowerLight"].nominalCellCount==2)
API.registerLight{item="Test.LateLight"}
assert(API.registerPowerProfiles() and registered["Test.LateLight"],"late verified lights must reach the power registry")
canonical.consumeEnergy=nil
assert(not API.registerPowerProfiles(),"incomplete power APIs must fail closed")
print("maintained power dependency, precedence, late registry and feature detection pass")
