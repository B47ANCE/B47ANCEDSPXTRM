local Ray=require "lightWorks/lightWorks_UVOcclusion"
local boundary="Clear"
local calls=0
local cell={getGridSquare=function(_,x,y,z)
    if x==99 then return nil end
    return {testVisionAdjacent=function(_,dx,dy,dz,diagonal,ignoreDoors)
        calls=calls+1
        assert(math.abs(dx)<=1 and math.abs(dy)<=1 and dz==0 and diagonal and not ignoreDoors)
        return x==1 and boundary or "Clear"
    end}
end}
local source={x=.5,y=.5,z=0}
local target={x=4.5,y=.5,z=0}
assert(Ray.trace(cell,source,target)==1 and calls==4)
for _,block in ipairs({"Blocked","ClearThroughClosedDoor"}) do
    boundary=block
    assert(Ray.trace(cell,source,target)==0)
end
boundary="ClearThroughOpenDoor"
assert(Ray.trace(cell,source,target)==1)
boundary="ClearThroughWindow"
assert(not Ray.trace(cell,source,target),"window policy cannot be silently invented")
assert(Ray.trace(cell,source,target,{windowTransmission=.25})==.25)
assert(Ray.trace(cell,source,target,{windowTransmission=0})==0)
boundary="FutureUnknownResult"
assert(not Ray.trace(cell,source,target))
boundary="Clear"
assert(Ray.trace(cell,source,{x=4.5,y=4.5,z=0})==1)
assert(Ray.trace(cell,source,{x=-4.5,y=-4.5,z=0})==1)
assert(Ray.trace(cell,source,{x=.5,y=.5,z=1})==0)
assert(not Ray.trace(cell,source,{x=99,y=.5,z=0}))
assert(not Ray.trace(cell,source,{x=999,y=.5,z=0}))
assert(not Ray.trace(cell,source,{x=0/0,y=0,z=0}))
assert(not Ray.trace({},source,target))
assert(Ray.trace(cell,source,source)==1)
print("lightWorks bounded UV obstruction ray checks passed")
