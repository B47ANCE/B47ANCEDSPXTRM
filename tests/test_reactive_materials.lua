local M=require "lightWorks/lightWorks_ReactiveMaterials"
local sample={artificialComplete=true,uv={uva=.04,uvb=0,uvc=0}}
local result=assert(M.evaluate("lightWorks.UntreatedBlood",sample))
assert(result.active and result.response=="absorption" and not result.identityConfirmed)
result.color.r=1
assert(M.evaluate("lightWorks.UntreatedBlood",sample).color.r==.055)
sample.uv.uva=0;assert(not M.evaluate("lightWorks.UntreatedBlood",sample).active)
sample.uv.uvc=1;assert(not M.evaluate("lightWorks.FluorescentMarker",sample).active,"UVC cannot substitute for UVA excitation")
sample.artificialComplete=false;assert(not M.evaluate("lightWorks.UntreatedBlood",sample))
sample.artificialComplete=true;sample.uv.uva=0/0;assert(not M.evaluate("lightWorks.UntreatedBlood",sample))
local def={id="Test.Material",response="reflectance",threshold=.1,strength=.5,excitation={uva=1,uvb=0,uvc=0},color={r=1,g=0,b=0}}
assert(M.register(def));def.excitation.uva=0;def.color.r=0
assert(M.evaluate("Test.Material",{artificialComplete=true,uv={uva=1,uvb=0,uvc=0}}).color.r==1)
assert(not pcall(M.register,def))
assert(not pcall(M.register,{id="bad",response="chemiluminescence"}),"time-owned chemical effects require a different owner contract")
print("bounded optical material contracts preserve snapshots and reject unknown exposure; native rendering remains unproved")
