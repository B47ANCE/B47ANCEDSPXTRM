local E=require "lightWorks/lightWorks_ConsumerExposure"
local C=require "lightWorks/lightWorks_ConsumerIntegrations"
local inspections,queries=0,0
farmWorks={inspectCrop=function(crop)
    inspections=inspections+1
    if crop.invalid then return nil end
    return {x=crop.x,y=1,z=0,cropType="Carrots",source=crop}
end}
E.sampleMany=function(points)
    queries=queries+1
    local observations={}
    for index,point in ipairs(points)do observations[index]={complete=true,naturalVisible=0,
        artificialVisible=point.x,totalVisible=point.x,uv={uva=0,uvb=0,uvc=.5},scope="fixture",radius=16}end
    return observations,{scans=1,points=#points}
end
local crops={};for i=1,35 do crops[i]={x=i/10,waterLvl=45,nbOfGrow=3}end
crops[2].invalid=true
local page=assert(C.cropLightingBatch(crops))
assert(#page.results==16 and page.nextCursor==16 and inspections==16 and queries==1)
assert(page.sampled==15 and page.rejected==1 and not page.complete and page.results[2].index==2 and not page.results[2].ok)
local observation=page.results[1].observation
assert(observation.source==nil and observation.growthEffect=="NONE")
observation.uv.uvc=100;assert(crops[1].waterLvl==45 and crops[1].nbOfGrow==3)
local second=assert(C.cropLightingBatch(crops,{cursor=16,limit=32}))
assert(#second.results==19 and second.nextCursor==nil and second.complete and inspections==35 and queries==2)
local empty=assert(C.cropLightingBatch(crops,{cursor=35}));assert(#empty.results==0 and queries==2)
assert(not C.cropLightingBatch(crops,{limit=33}) and not C.cropLightingBatch(crops,{cursor=0/0}))
assert(not C.cropLightingBatch(crops,{cursor=false}) and not C.cropLightingBatch(crops,{limit=false}))
assert(not C.cropLightingBatch(crops,{cursor=36}) and queries==2)
E.sampleMany=function()return nil,"batch span exceeds scan budget"end
local far=assert(C.cropLightingBatch(crops,{limit=1}));assert(far.rejected==1 and far.sampled==0 and not far.complete)
farmWorks=nil
local unavailable=assert(C.cropLightingBatch(crops,{limit=1}));assert(unavailable.rejected==1 and not unavailable.complete)
print("paged crop query caps, stable input indices, detached observations and explicit failures pass")
