isDebugEnabled=function()return true end
isClient=function()return true end
-- Native/UI modules are not used because mutation guards must run before any
-- player/inventory lookup, creation, timed action or visual-tour mutation.
for _,name in ipairs({"lightWorks/lightWorks_ChangeBulbAction","TimedActions/ISTimedActionQueue","ISUI/ISTextBox"})do package.loaded[name]=true end
Events={OnTick={Add=function()end}}
getSpecificPlayer=function()error("client must not inspect/spawn fixture inventory")end
local H=require "lightWorks/lightWorks_TestHarness"
for _,name in ipairs({"giveKit","queueChange","queueRemove","queueCycle","runChecks","startTour","startReleaseSuite"})do
    assert(not H[name](),"client fixture helper must refuse: "..name)
end
isClient=function()return false end;isServer=function()return true end
assert(not H.giveKit() and not H.runChecks(),"host/dedicated contexts are not single-player fixtures")
print("all manual mutating fixture helpers refuse multiplayer before native inventory access")
