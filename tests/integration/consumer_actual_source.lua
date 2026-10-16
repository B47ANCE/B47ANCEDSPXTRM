-- The runner supplies actual dependency search paths. No compatibility globals
-- or package.loaded shims replace first-party APIs; only native objects are fake.
local API=require "lightWorks/lightWorks_API"
require "lightWorks/lightWorks_Vanilla"
local C=require "lightWorks/lightWorks_ConsumerIntegrations"
require "ProjectNightfall/PN_FlashlightBulbs"
assert(C.refreshNightfall())
assert(API.getBulbProfile("ProjectNightfall.LightBulbUV").emissions.UV.spectrum==nil,
    "Nightfall's current bulb definition must not be reclassified as UVC")
local Migration=require "lightWorks/lightWorks_LegacyMigration"
getActivatedMods=function()return {size=function()return 0 end}end
for old,current in pairs(C.aliasContract().aliases) do
    local data={Bulbworks={hasExplicitBulbState=true,installedBulb=old,burnMinutes=19,burnedOut=false}}
    local light={getID=function()return 42 end,getFullType=function()return "Base.Torch"end,
        getModData=function()return data end,transmitModData=function()end,syncItemFields=function()end}
    assert(Migration.process(light) and data.lightWorks.installedBulb==current and data.lightWorks.burnMinutes==19)
end
local Sunburn=require "lightWorks/lightWorks_Sunburn"
require "medWorks/SunburnTreatment"
local patient={data={lightWorksSunburn={schemaVersion=1,dose=.8,severity=.3,processedOperations={}}},
    getModData=function(self)return self.data end,transmitModData=function()end}
local ok,reason=C.treatSunburn(patient,.1,"actual-medical-1","disposable-server-action")
assert(ok,tostring(reason));assert(math.abs(Sunburn.getState(patient).dose-.7)<1e-8)
assert(not C.treatSunburn(patient,.1,"actual-medical-1","disposable-server-action"))
local water=require "waterWorks/API"
local farm=require "farmWorks/API"
local Fixtures=require "lightWorks/lightWorks_Fixtures"
local lamp={getX=function()return .5 end,getY=function()return .5 end,getZ=function()return 0 end}
local uvc=1
Fixtures.register{id="probe.fixture",inspect=function(object)
    if object~=lamp then return end
    return {known=true,active=true,powered=true,range=10,intensity=1,
        uv={intensity=2,range=10,spectrum={uva=1-uvc,uvb=0,uvc=uvc}}}
end}
local empty={size=function()return 0 end}
local objects={size=function()return 1 end,get=function()return lamp end}
local vision="Clear"
getCell=function()return {getGridSquare=function(_,x,y)return {
    getObjects=function()return x==0 and y==0 and objects or empty end,getWorldObjects=function()return empty end,
    isOutside=function()return false end,testVisionAdjacent=function()return vision end}end}end
local owner={data={},tainted=true,getX=function()return 4.5 end,getY=function()return .5 end,getZ=function()return 0 end,
    getWaterAmount=function()return 5 end,getWaterMax=function()return 10 end,
    getModData=function(self)return self.data end,isTaintedWater=function(self)return self.tainted end,
    setTaintedWater=function(self,value)self.tainted=value end,transmitModData=function()end}
local quality={biological=.8,particulate=.2,chemical=.3,salinity=.4,turbidity=.1}
assert(water.setQuality(owner,quality))
assert(not C.treatWater(owner,"actual-water-1"),"disabled sandbox default")
API.Config.EnableWaterUVIntegration=true
uvc=0;assert(not C.treatWater(owner,"actual-water-1"),"actual source path must refuse UVA")
uvc=1;vision="ClearThroughWindow";assert(not C.treatWater(owner,"actual-water-1"))
vision="Clear";assert(C.treatWater(owner,"actual-water-1"))
local after=water.getQuality(owner)
assert(math.abs(after.biological-.08)<1e-8 and after.chemical==.3 and after.salinity==.4 and after.particulate==.2)
assert(not C.treatWater(owner,"actual-water-1"),"retained history rejects replay")
local savedSet=water.setQuality;local first=true
water.setQuality=function(...)
    if first then first=false;return false,"injected quality-write failure" end
    return savedSet(...)
end
assert(not C.treatWater(owner,"actual-water-rollback"))
water.setQuality=savedSet
assert(math.abs(water.getQuality(owner).biological-after.biological)<1e-8)
assert(#owner.data.waterWorksTreatmentHistory==1 and owner.data.waterWorksTreatmentRecovery==nil)
local crop={typeOfSeed="Carrots",waterLvl=45,nbOfGrow=3,x=4.5,y=.5,z=0}
local light=assert(C.cropLighting(crop));assert(light.complete and light.artificialVisible>0)
assert(light.growthEffect=="NONE" and light.source==nil and crop.waterLvl==45 and crop.nbOfGrow==3)
local crop2={typeOfSeed="Carrots",waterLvl=50,nbOfGrow=4,x=8.5,y=.5,z=0}
local page=assert(C.cropLightingBatch({crop,crop2}))
assert(page.complete and page.sampled==2 and page.query.scans==1)
assert(page.results[1].observation.artificialVisible==light.artificialVisible)
assert(crop2.waterLvl==50 and crop2.nbOfGrow==4)
isClient=function()return true end
assert(not C.treatWater(owner,"actual-client") and not C.treatSunburn(patient,.1,"actual-client","source"))
assert(C.cropLighting(crop),"observation remains client-safe")
assert(powerWorks==nil and experienceWorks==nil,"do not hide obsolete loader contracts with globals")
print("PASS actual Nightfall aliases, Medical procedure replay, Water transaction/rollback, Farming single/batch observations")
