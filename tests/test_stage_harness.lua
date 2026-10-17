isDebugEnabled=function()return true end
package.loaded["lightWorks/lightWorks_StageHarness"]=nil
local output={};getFileWriter=function(name,create,append)assert(name=="theWorks Test Results - lightWorks.txt"and create and not append);output={};return{writeln=function(_,line)output[#output+1]=line end,close=function()end}end
getCore=function()return{getVersionNumber=function()return"42.20.3-test"end}end
local player={modData={}};function player:getModData()return self.modData end;getSpecificPlayer=function()return player end
SandboxVars={lightWorks={EnableWorldEmitters=true}};powerWorks={getConsumerPowerState=function()end}
local API={VERSION="0.25.2"};function API.isRegisteredLight(v)return v=="Base.HandTorch"end;function API.isRegisteredBulb(v)return v=="Base.LightBulbRed"end;API.getEmission=function()end;API.installBulb=function()end;API.supportsWorldEmission=function()end;_G.lightWorks=API
local completion;package.loaded["lightWorks/lightWorks_TestHarness"]={runChecks=function()return true,{passed=8,failed=0}end,whenTourCompletes=function(fn)completion=fn;return true end,startTour=function()return true end}
local Harness=require"lightWorks/lightWorks_StageHarness";assert(Harness.start(true)==true);local session=player.modData["lightWorks.StageTestSession.V1"];assert(session.results.startup.status=="PASS")
assert(Harness.checks()==true and session.results.core.status=="PASS");assert(Harness.tour()==false and session.results.visual_tour==nil);completion({{report="PASS"},{report="beam missing"}});assert(session.results.visual_tour.status=="FAIL")
assert(Harness.sandbox()==false and session.results.sandbox==nil);SandboxVars.lightWorks.EnableWorldEmitters=false;assert(Harness.sandbox()==true and session.results.sandbox.status=="PASS")
assert(Harness.reloadStatus()==false);package.loaded["lightWorks/lightWorks_StageHarness"]=nil;Harness=require"lightWorks/lightWorks_StageHarness";assert(Harness.reloadStatus()==true)
for _=1,140 do Harness.auto()end;assert(#session.commands==128);assert(Harness.report()==true);local joined=table.concat(output,"\n");assert(joined:find("Mod ID: lightWorks",1,true));print("lightWorks stage report harness checks passed")
