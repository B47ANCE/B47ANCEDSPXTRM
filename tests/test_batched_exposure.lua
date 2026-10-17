local API=require "lightWorks/lightWorks_API"
local E=require "lightWorks/lightWorks_ConsumerExposure"
local S=require "lightWorks/lightWorks_EmissionSources"
local F=require "lightWorks/lightWorks_Fixtures"
local object={getX=function()return .5 end,getY=function()return .5 end,getZ=function()return 0 end}
local far={getX=function()return 24.5 end,getY=function()return .5 end,getZ=function()return 0 end}
local additional=false
local active=true
F.register{id="batch",inspect=function(got)if got==object or got==far then return{known=true,active=active,powered=true,
    range=24,intensity=.8,uv={range=24,intensity=2,spectrum={uva=0,uvb=0,uvc=1}}}end end}
local empty={size=function()return 0 end}
local objects={size=function()return 1 end,get=function()return object end}
local farObjects={size=function()return 1 end,get=function()return far end}
local blocked=false
getCell=function()return{getGridSquare=function(_,x,y,z)return {
    getObjects=function()if x==24 and y==0 and additional then return farObjects end;return x==0 and y==0 and objects or empty end,getWorldObjects=function()return empty end,
    isOutside=function()return false end,
    testVisionAdjacent=function(_,dx)return blocked and x<6 and x+dx>=6 and "Blocked" or "Clear"end}end}end
local scans=0
local original=S.collectWorld
S.collectWorld=function(...)scans=scans+1;return original(...) end
local points={E.point(4.5,.5,0),E.point(8.5,.5,0)}
local samples,query=E.sampleMany(points)
assert(samples and scans==1 and query.scans==1 and query.points==2 and query.scanRadius==18)
assert(samples[1].complete and samples[2].complete and samples[1].uv.uvc>samples[2].uv.uvc)
for index,point in ipairs(points) do
    local single=assert(E.sample(point))
    assert(single.artificialVisible==samples[index].artificialVisible and single.uv.uvc==samples[index].uv.uvc)
end
samples[1].scan.complete=false;assert(samples[2].scan.complete,"observations must not share mutable scan tables")
samples[1].uv.uvc=100
blocked=true
local wall=assert(E.sampleMany(points));assert(wall[1].uv.uvc>0 and wall[2].uv.uvc==0)
active=false;local off=assert(E.sampleMany(points));assert(off[1].uv.uvc==0 and off[2].artificialVisible==0)
active=true;blocked=false;assert(E.sample(points[1]).uv.uvc<100,"no stale observations survive a new call")
additional=true
local scoped=assert(E.sampleMany(points))
assert(scoped[1].uv.uvc==E.sample(points[1]).uv.uvc and scoped[2].uv.uvc==E.sample(points[2]).uv.uvc)
assert(scoped[1].sourceCount==1 and scoped[2].sourceCount==2,"union capture must preserve each target's 16-tile scope")
additional=false
local before=scans
assert(not E.sampleMany({}))
assert(not E.sampleMany({points[1],E.point(100,0,0)}))
assert(not E.sampleMany({points[1],E.point(4,0,1)}))
assert(not E.sampleMany({points[1],label="invalid"}))
assert(not E.sampleMany({{x=0/0,y=0,z=0}}))
local many={};for i=1,33 do many[i]=points[1] end
assert(not E.sampleMany(many) and scans==before,"invalid or over-budget batches must fail before world scans")
many[33]=nil
assert(E.sampleMany(many) and scans==before+1,"maximum page uses one capture")
S.collectWorld=function(...)local sources=original(...);return sources,{complete=false,reason="fixture budget"}end
local incomplete=assert(E.sampleMany(points))
assert(not incomplete[1].artificialComplete and not incomplete[2].artificialComplete)
print("one-scan clustered exposure, parity, fresh state, walls, detached results and hard budgets pass")
