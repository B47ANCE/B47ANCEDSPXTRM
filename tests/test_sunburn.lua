local exposure=.8;local complete=true
local lightWorks={Config={EnableSunburn=true,SunburnDoseMultiplier=1,SunburnFirstDegreeDoseHours=.5,
    SunburnMaximumDoseHours=2,SunburnRecoveryDoseHoursPerHour=.25}}
package.loaded["lightWorks/lightWorks_API"]=lightWorks
package.loaded["lightWorks/lightWorks_UV"]={getSunlightExposure=function()return{uv={uvb=exposure,natural=exposure,artificial=99,complete=complete}}end}
local Sunburn=dofile(arg[1])
local character={data={},transmits=0}
function character:getModData()return self.data end
function character:transmitModData()self.transmits=self.transmits+1 end

assert(Sunburn.update(character,0).severity==0)
Sunburn.update(character,.25);Sunburn.update(character,.50)
local burned=Sunburn.update(character,.75)
assert(burned.severity>0 and burned.lastNaturalUV==.8,"natural UV dose must produce persistent severity")
assert(character.transmits==3,"canonical changes must transmit")

Sunburn.registerProtectionProvider("test.clothing",function()return .5 end)
local protection,details=Sunburn.getProtection(character,{})
assert(protection==.5 and details["test.clothing"]==.5,"protection providers must be inspectable")
local before=Sunburn.getState(character).dose
Sunburn.update(character,1.0)
assert(Sunburn.getState(character).dose-before<.1,"protection must reduce incoming dose")

exposure=0
local sheltered=Sunburn.update(character,1.25)
assert(sheltered.dose<Sunburn.getState(character).dose+.1,"shelter must recover dose")
local treated,after=Sunburn.applyTreatment(character,.2,"treatment-1")
assert(treated and after.dose<sheltered.dose,"authoritative treatment must reduce dose")
assert(not Sunburn.applyTreatment(character,.2,"treatment-1"),"treatment operations must reject replay")

complete=false;exposure=0
local beforeUnknown=Sunburn.getState(character);local transmitted=character.transmits
local unchanged,reason=Sunburn.update(character,1.5)
assert(unchanged.dose==beforeUnknown.dose and unchanged.severity==beforeUnknown.severity and reason=="exposure incomplete",
    "unknown exposure cannot apply dose or sheltered recovery")
assert(character.data.lightWorksSunburn.lastWorldAgeHours==1.5 and character.transmits==transmitted,
    "unknown intervals must be checkpointed without replaying them as known exposure")
complete=true;local recovered=Sunburn.update(character,1.75)
assert(math.abs(unchanged.dose-recovered.dose-.03125)<.000001,"known shelter may recover only the subsequent known interval")
isClient=function()return true end
assert(Sunburn.update(character,2)==nil and not Sunburn.applyTreatment(character,.1,"client"),"clients must not mutate canonical sunburn")
isClient=function()return false end
local future={schemaVersion=99,dose=.8};character.data.lightWorksSunburn=future
assert(Sunburn.update(character,3)==nil and character.data.lightWorksSunburn==future,
    "future sunburn schemas must be rejected without being reset")
print("lightWorks persistent authority-owned sunburn checks passed")

character.data.lightWorksSunburn={schemaVersion=1,dose=.5,severity=.2,lastWorldAgeHours=5,processedOperations={}}
Sunburn.update(character,4)
assert(character.data.lightWorksSunburn.lastWorldAgeHours==5,"backward time must not rewind the checkpoint")
local corrupt={schemaVersion=1,dose=.5,severity=.2,processedOperations="corrupt"};character.data.lightWorksSunburn=corrupt
assert(not Sunburn.applyTreatment(character,.1,"bad-history") and character.data.lightWorksSunburn==corrupt
    and corrupt.processedOperations=="corrupt","malformed replay history must be retained")
