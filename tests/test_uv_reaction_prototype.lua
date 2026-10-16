local sourcePath=assert(arg[1],"prototype source path required")
local renderCalls=0
local sprite={renderBloodSplat=function(_,x,y,z,color)
    renderCalls=renderCalls+1
    assert(x==10.5 and y==20.5 and z==0)
    assert(color.b==1.0)
end}
local splat={x=2.5,y=4.5,z=0,type=0}
local queue={size=function() return 1 end,get=function(_,index) return index==0 and splat or nil end}
local empty={size=function() return 0 end,get=function() return nil end}
local chunk={wx=1,wy=2,floorBloodSplats=queue,floorBloodSplatsFade=empty}
local square={}
local player={
    getX=function() return 10.5 end,getY=function() return 20.5 end,getZ=function() return 0 end,
    getSquare=function() return square end,
}
lightWorks={}
local realRequire=require
require=function(name) if name=="lightWorks/lightWorks_API" then return lightWorks end return realRequire(name) end
getSpecificPlayer=function(index) return index==0 and player or nil end
getCell=function() return {getChunkForGridSquare=function() return chunk end} end
ColorInfo={new=function(r,g,b,a) return {r=r,g=g,b=b,a=a} end}
IsoFloorBloodSplat={FLOOR_BLOOD_TYPES={[0]="blood"},spriteMap={get=function(_,key) return key=="blood" and sprite or nil end}}
local renderHandler
Events={OnPostFloorLayerDraw={Add=function(callback) renderHandler=callback end}}
local placed=0
addBloodSplat=function(gotSquare,count) assert(gotSquare==square);placed=count end
dofile(sourcePath)
assert(LWUVBloodTest("fluorescence"))
renderHandler(0)
assert(renderCalls==1,"nearby native splat should be redrawn once")
local status=LWUVBloodTest("status")
assert(status.lastDetected==1 and status.lastRendered==1 and status.lastMissingSprite==0)
assert(LWUVBloodTestPlace(200) and placed==40,"sample placement must clamp its persistent change")
assert(LWUVBloodTest("off") and not status.active)
print("lightWorks UV-reaction prototype checks passed")
