local hooks=0
Events={OnPostFloorLayerDraw={Add=function()hooks=hooks+1 end}}
local inert=require "lightWorks/lightWorks_UVReactionPrototype"
assert(hooks==0 and next(inert)==nil and LWUVBloodTestPlace==nil,
    "missing debug capability must install neither hooks nor persistent fixture commands")
package.loaded["lightWorks/lightWorks_UVReactionPrototype"]=nil
isDebugEnabled=function()return false end
local disabled=require "lightWorks/lightWorks_UVReactionPrototype"
assert(hooks==0 and next(disabled)==nil and LWUVBloodTestPlace==nil)
isDebugEnabled=nil
for _,name in ipairs({"TestHarness","StageHarness","ModelRotationProbe"})do
    local empty=require("lightWorks/lightWorks_"..name)
    assert(next(empty)==nil,"missing debug capability must leave all development helpers inert")
end
print("native blood prototype remains inert unless debug capability is positively confirmed")
