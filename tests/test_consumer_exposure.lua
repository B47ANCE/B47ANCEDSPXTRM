local API=require "lightWorks/lightWorks_API"
local Sources=require "lightWorks/lightWorks_EmissionSources"
local E=require "lightWorks/lightWorks_ConsumerExposure"
local Fixtures=require "lightWorks/lightWorks_Fixtures"
local lamp={getX=function()return .5 end,getY=function()return .5 end,getZ=function()return 0 end}
local facts={known=true,active=true,powered=true,range=10,intensity=1,directional=false,
    uv={intensity=2,range=10,spectrum={uva=0,uvb=0,uvc=1}}}
Fixtures.register{id="test",inspect=function(object)if object==lamp then return facts end end}
local empty={size=function()return 0 end}
local objects={size=function()return 1 end,get=function()return lamp end}
local vision="Clear"
local cell={getGridSquare=function(_,x,y,z)return{
    getObjects=function()return x==0 and y==0 and objects or empty end,getWorldObjects=function()return empty end,
    testVisionAdjacent=function()return vision end,isOutside=function()return false end}end}
getCell=function()return cell end
assert(not E.point(1e308,0,0))
local _,bad=Sources.collectWorld({x=1e308,y=0,z=0},16,64)
assert(not bad.complete,"extreme finite coordinates must not stall a bounded scan")
local _,missing=Sources.collectWorld({getX=function()return 1 end},16,64)
assert(not missing.complete,"partial coordinates must fail without arithmetic errors")
local p=E.point(4.5,.5,0)
local sample=assert(E.sample(p));assert(sample.complete and sample.artificialComplete and sample.uv.uvc>0 and sample.artificialVisible>0)
vision="Blocked";sample=assert(E.sample(p));assert(sample.complete and sample.uv.uvc==0 and sample.artificialVisible==0)
vision="ClearThroughWindow";sample=assert(E.sample(p));assert(sample.complete and sample.uv.uvc==0 and sample.artificialVisible>0)
vision="Unknown";assert(not E.sample(p).artificialComplete)
vision="Clear";facts.directional=true;facts.orientation=180;assert(E.sample(p).uv.uvc==0)
facts.orientation=90;assert(E.sample(p).uv.uvc>0)
local _,scan=Sources.collectWorld(p,16,1);assert(not scan.complete and scan.reason=="source budget")
local goodSize=objects.size
objects.size=function()return 0/0 end
assert(not E.sample(p).artificialComplete,"unknown collections are not known darkness")
objects.size=goodSize
local original=Sources.collectWorld
Sources.collectWorld=function(...)local list=original(...);return list,{complete=false,reason="fixture budget"}end
assert(not E.sample(p).artificialComplete,"partial scans cannot authorize treatment")
getCell=function()return nil end
assert(not E.sample(p) and not E.position({}) and not E.point(math.huge,0,0))
print("real fixture/source/UV path, walls, glass, cones, unknown geometry and scan limits pass")
