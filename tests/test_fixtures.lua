local API=require "lightWorks/lightWorks_API"
local Sources=require "lightWorks/lightWorks_EmissionSources"
local Fixtures=require "lightWorks/lightWorks_Fixtures"
local object={getX=function()return 1 end,getY=function()return 2 end,getZ=function()return 0 end}
local facts={known=true,active=true,powered=true,range=10,intensity=.8,directional=true,orientation=25,
    uv={intensity=2,range=8,spectrum={uva=1,uvb=0,uvc=0}}}
Fixtures.register{id="test",customPresentation=true,inspect=function(got)if got==object then return facts end end}
local source=assert(Sources.inspect(object));assert(source.customPresentation and source.channels.UV and source.uvIntensity==2)
assert(source.color.b==1 and source.color.r==0 and source.directionX>0,"UV color and free angle semantics must match rendering")
source.color.b=0;assert(Sources.inspect(object).color.b==1,"snapshots cannot mutate provider or canonical UV color")
facts.known=false;assert(not Sources.inspect(object));facts.known=true
facts.range=math.huge;assert(not Sources.inspect(object));facts.range=10
facts.uv.spectrum.uvc=0/0;assert(not Sources.inspect(object));facts.uv.spectrum.uvc=0
assert(Fixtures.unregister("test") and not Sources.inspect(object))
print("advanced fixture contracts and unknown-state rejection pass")
