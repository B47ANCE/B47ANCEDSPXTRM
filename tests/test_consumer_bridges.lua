local API=require "lightWorks/lightWorks_API"
local E=require "lightWorks/lightWorks_ConsumerExposure"
local C=require "lightWorks/lightWorks_ConsumerIntegrations"
assert(not C.treatSunburn({},.1,"op","source"))
local called=0
medWorks={Procedures={[C.MEDICAL_PROCEDURE]={}},performProcedure=function(id,context)
    called=called+1;assert(id==C.MEDICAL_PROCEDURE and context.operationId=="op");return true,"result"
end}
assert(C.treatSunburn({},.1,"op","source") and called==1)
for _,amount in ipairs({0,.51,0/0,math.huge}) do assert(not C.treatSunburn({},amount,"op","source")) end
assert(not C.treatSunburn({},.1,"bad\n","source"))
isClient=function()return true end
assert(not C.treatSunburn({},.1,"op","source") and not C.treatWater({},"op"))
isClient=function()return false end
local data={};local owner={getModData=function()return data end}
local quality={biological=.8,particulate=.2,chemical=.3,salinity=.4,turbidity=.1}
local view={amount=5,kind="legacy-water"}
local uvc,complete=1,true
E.position=function(got)assert(got==owner);return {} end
E.sample=function()return {artificialComplete=complete,uv={uvc=uvc},complete=true,
    naturalVisible=.5,artificialVisible=1,totalVisible=1.5,scope="fixture",radius=16} end
waterWorks={Treatments={},getContainer=function()return{owner=owner}end,inspectContainer=function()return view end,
    registerTreatment=function(def)waterWorks.Treatments[def.id]=def end,
    applyTreatment=function(got,id,context)
        local def=waterWorks.Treatments[id];local ok,reason=def.validate(got,quality,context)
        if not ok then return false,reason end
        return true,def.transform(quality)
    end}
assert(C.registerWater() and not C.treatWater(owner,"op"),"disabled by default")
API.Config.EnableWaterUVIntegration=true
uvc=0;assert(not C.treatWater(owner,"op"),"UVA must never substitute for UVC")
uvc=1;complete=false;assert(not C.treatWater(owner,"op"));complete=true
quality.turbidity=.9;assert(not C.treatWater(owner,"op"));quality.turbidity=.1
view.kind="fluid";view.capabilities={waterSource=true,mixture=true};assert(not C.treatWater(owner,"op"))
view.capabilities.mixture=false
data.waterWorksTreatmentHistory={{operationId="op"}};assert(not C.treatWater(owner,"op"))
data.waterWorksTreatmentHistory={[2]={}};assert(not C.treatWater(owner,"op"))
data.waterWorksTreatmentHistory="corrupt";assert(not C.treatWater(owner,"op"))
data.waterWorksTreatmentHistory=nil
assert(C.treatWater(owner,"op"))
assert(math.abs(quality.biological-.08)<1e-8 and quality.chemical==.3 and quality.salinity==.4 and quality.particulate==.2)
waterWorks.Treatments[C.WATER_TREATMENT]={owner="someone else"};assert(not C.registerWater())
local crop={waterLvl=40,nbOfGrow=3}
farmWorks={inspectCrop=function(got)assert(got==crop);return{x=1,y=2,z=0,cropType="Carrots",source=crop}end}
local result=assert(C.cropLighting(crop));assert(result.source==nil and result.growthEffect=="NONE")
result.uv.uvc=9;assert(crop.waterLvl==40 and crop.nbOfGrow==3)
farmWorks.inspectCrop=function()return{x=0/0,y=2,z=0}end
E.sample=function(point)if not point then return nil,"invalid point" end end
assert(not C.cropLighting(crop))
print("authority, Medical delegation, UVC quality gates, duplicate history and read-only crops pass")
