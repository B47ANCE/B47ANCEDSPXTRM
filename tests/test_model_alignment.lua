local API=require "lightWorks/lightWorks_API"
local M=require "lightWorks/lightWorks_ModelAlignment"
local data={lightWorksWorldEmitter={schemaVersion=1,orientation="E"}}
local yaw,mode,sends=15,"ok",0
local item,object
object={getItem=function()return item end,getSquare=function()return {} end,
    transmitCompleteItemToClients=function()sends=sends+1;if mode=="syncFail" then error("sync failure") end end}
item={getFullType=function()return "Test.Lamp" end,getWorldItem=function()return object end,
    getModData=function()return data end,transmitModData=function()end,getWorldZRotation=function()return yaw end,
    setWorldZRotation=function(_,value)if mode=="stuck"then error("stuck")end;yaw=value;if mode=="afterWrite"then error("after write")end end}
API.registerLight{item="Test.Lamp",emitter={cone=true}}
local definition={item="Test.Lamp",northYaw=30,clockwiseSign=-1,evidenceId="test-calibration"}
assert(M.register(definition));definition.northYaw=200
local view=M.profile(item);view.northYaw=250
assert(not M.apply(item) and yaw==15)
API.Config.EnableNativeModelAlignment=true
assert(M.apply(item) and yaw==300 and sends==1 and data.lightWorksNativeModelRecovery==nil)
assert(M.apply(item) and sends==1,"already aligned must not resync")
data.lightWorksWorldEmitter.orientation=27.5
assert(M.apply(item) and math.abs(yaw-2.5)<1e-8)
mode="afterWrite";data.lightWorksWorldEmitter.orientation="N"
assert(not M.apply(item) and math.abs(yaw-2.5)<1e-8 and not data.lightWorksNativeModelRecovery,"rollback verified despite throwing setter")
mode="syncFail"
assert(not M.apply(item) and data.lightWorksNativeModelRecovery,"unproved transport retains recovery")
mode="ok";assert(not M.apply(item),"uncertain record blocks further writes")
assert(M.restore(item) and data.lightWorksNativeModelRecovery==nil)
isClient=function()return true end
assert(not M.apply(item) and not M.restore(item))
isClient=function()return false end
local saved=item.getWorldItem;item.getWorldItem=function()return nil end
assert(not M.apply(item));item.getWorldItem=saved
assert(data.lightWorksWorldEmitter.orientation=="N","presentation never rewrites optical state")
assert(not pcall(M.register,{item="Other.Lamp",northYaw=0,clockwiseSign=1}),"evidence is mandatory")
assert(not pcall(M.register,{item="Other.Lamp",northYaw=0/0,clockwiseSign=1,evidenceId="bad"}))
print("calibrated native alignment: authority, no guessed mapping, readback, sync, rollback and durable recovery pass")
