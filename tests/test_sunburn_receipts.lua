local S=require "lightWorks/lightWorks_Sunburn"
local data={};local actor={getModData=function()return data end,transmitModData=function()end}
assert(S.hasProcessedTreatment(actor,"new")==false and data.lightWorksSunburn==nil)
data.lightWorksSunburn={schemaVersion=1,dose=.8,severity=.3}
assert(S.hasProcessedTreatment(actor,"new")==false and data.lightWorksSunburn.processedOperations==nil)
assert(S.applyTreatment(actor,.1,"new"))
assert(S.hasProcessedTreatment(actor,"new")==true)
assert(S.getState(actor).processedOperations==nil,"public state snapshot must not expose raw replay history")
data.lightWorksSunburn.processedOperations=false;assert(S.hasProcessedTreatment(actor,"new")==nil)
assert(S.hasProcessedTreatment(actor,"")==nil)
print("read-only bounded treatment receipt query supports proven recovery without exposing raw history")
