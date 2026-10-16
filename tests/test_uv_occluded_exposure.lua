lightWorks={}
package.loaded["lightWorks/lightWorks_API"]=lightWorks
local UV=require "lightWorks/lightWorks_UV"
local function point(x,y,z) return {getX=function() return x end,getY=function() return y end,getZ=function() return z end} end
local target=point(4.5,.5,0)
local emitter={owner=point(.5,.5,0),range=10,intensity=2,spectrum={uva=1},directional=false}
local state="Clear"
local cell={getGridSquare=function(_,x)
    return {testVisionAdjacent=function() return x==1 and state or "Clear" end}
end}
local context={cell=cell,windowTransmission=.25}
local clear=UV.getOccludedArtificialExposure(target,{emitter},context).uv
assert(clear.complete and clear.occlusionChecked and #clear.sources==1)
assert(clear.sources[1].transmission==1)
state="Blocked"
local blocked=UV.getOccludedArtificialExposure(target,{emitter},context).uv
assert(blocked.complete and blocked.artificial==0 and blocked.blockedSources==1)
state="ClearThroughWindow"
local window=UV.getOccludedArtificialExposure(target,{emitter},context).uv
assert(window.complete and window.artificial==clear.artificial*.25)
assert(window.uva==window.artificial)
assert(not UV.getOccludedArtificialExposure(target,{emitter},{cell=cell}).uv.complete)
state="Clear"
local stacked=UV.getOccludedArtificialExposure(target,{emitter,emitter},context).uv
assert(stacked.artificial==2*clear.artificial and #stacked.sources==2)
local unknown=UV.getOccludedArtificialExposure(target,{emitter},{cell={}}).uv
assert(not unknown.complete and unknown.unknownSources==1 and unknown.artificial==0)
local many={}
for i=1,65 do many[i]=emitter end
local bounded=UV.getOccludedArtificialExposure(target,many,context).uv
assert(not bounded.complete and bounded.checkedSources==64)
assert(UV.getArtificialExposure(target,{emitter}).uv.occlusionChecked==false,
    "legacy behavior remains explicit until the consumer migration")
print("lightWorks obstruction-aware UV exposure aggregation checks passed")

target.getSquare=function() return {isOutside=function() return true end} end
getClimateManager=function() return {getDayLightStrength=function() return .8 end} end
local combined=UV.getVerifiedExposure(target,{emitter},context).uv
assert(combined.complete and combined.occlusionChecked and combined.natural==.8)
assert(combined.total==combined.natural+combined.artificial and #combined.sources==2)
getClimateManager=function() error("climate unavailable") end
assert(not UV.getVerifiedExposure(target,{emitter},context).uv.complete)
getClimateManager=function() return {getDayLightStrength=function() return 0 end} end
assert(UV.getVerifiedExposure(target,{},context).uv.complete,"verified darkness is a valid zero sample")
target.getSquare=function() return nil end
assert(not UV.getVerifiedExposure(target,{},context).uv.complete,"missing square is not darkness")
target.getSquare=function() return {isOutside=function() return false end} end
assert(UV.getVerifiedExposure(target,{},context).uv.complete)
UV.registerExposureModifier("broken",function() return 0/0 end)
assert(not UV.getVerifiedExposure(target,{},context).uv.complete)
print("lightWorks combined exposure completeness and unknown-versus-darkness checks passed")

assert(not UV.getOccludedArtificialExposure(target,{"broken"},context).uv.complete)
assert(not UV.getOccludedArtificialExposure(target,{{owner=emitter.owner,range=10,intensity=0/0}},context).uv.complete)
assert(not UV.getOccludedArtificialExposure(target,{{owner=emitter.owner,range=10,intensity=1,spectrum="broken"}},context).uv.complete)
assert(UV.getOccludedArtificialExposure(target,{{owner=emitter.owner,range=10,intensity=0}},context).uv.complete)
local overflow={owner=emitter.owner,range=10,intensity=1e308,spectrum={uva=1e308}}
local rejected=UV.getOccludedArtificialExposure(target,{overflow},context).uv
assert(not rejected.complete and rejected.artificial==0 and rejected.uva==0)
print("lightWorks malformed/overflow emitter completeness checks passed")
