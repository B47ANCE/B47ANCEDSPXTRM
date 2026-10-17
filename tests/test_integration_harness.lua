local inert=require "lightWorks/lightWorks_IntegrationHarness"
assert(next(inert)==nil)
assert(LWIntegrationKit==nil and LWIntegrationMigrateHeld==nil)
package.loaded["lightWorks/lightWorks_IntegrationHarness"]=nil
isDebugEnabled=function()return true end
isClient=function()return true end
local H=require "lightWorks/lightWorks_IntegrationHarness"
assert(not H.kit() and not H.migrateHeld(),"manual mutations must refuse MP clients")
isClient=function()return false end
assert(not H.kit() and not H.migrateHeld(),"missing local player cannot mutate")
getSpecificPlayer=function()return {} end
package.loaded["lightWorks/lightWorks_TestHarness"]={giveKit=function()return false,"inventory unavailable"end}
assert(not H.kit(),"failed base-kit preparation cannot report success")
package.loaded["lightWorks/lightWorks_TestHarness"].giveKit=function()return true,{missing={"Base.Torch"}} end
assert(not H.kit(),"incomplete base kits must be reported")
assert(H.status().contractVersion==1)
assert(H.cropBatch({}).sampled==0 and LWIntegrationCropLightingBatch==H.cropBatch)
print("debug helpers inert outside debug mode and guarded against client mutations")
