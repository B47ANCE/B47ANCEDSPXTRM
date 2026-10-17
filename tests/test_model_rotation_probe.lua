local inert=require "lightWorks/lightWorks_ModelRotationProbe"
assert(next(inert)==nil and LWModelRotationPreview==nil)
package.loaded["lightWorks/lightWorks_ModelRotationProbe"]=nil
isDebugEnabled=function()return true end
local API=require "lightWorks/lightWorks_API"
API.registerLight{item="Test.Light",emitter={cone=true}}
local data={lightWorksWorldEmitter={orientation="N",schemaVersion=1}}
local item={yaw=35.5,getFullType=function()return "Test.Light"end,getModData=function()return data end,
    getWorldZRotation=function(self)return self.yaw end,setWorldZRotation=function(self,value)self.yaw=value end}
local backing={getItem=function()return item end,getX=function()return 1 end,getY=function()return 1 end,getZ=function()return 0 end}
item.getWorldItem=function()return backing end
local player={getX=function()return 1 end,getY=function()return 1 end,getZ=function()return 0 end}
getSpecificPlayer=function()return player end
local remove
Events={OnObjectAboutToBeRemoved={Add=function(fn)remove=fn end}}
local P=require "lightWorks/lightWorks_ModelRotationProbe"
isClient=function()return true end
assert(not P.preview(item,90) and item.yaw==35.5)
isClient=function()return false end
isServer=function()return true end;assert(not P.preview(item,90));isServer=function()return false end
assert(not P.preview(item,0/0) and not P.preview(item,360))
assert(P.preview(item,90) and item.yaw==90 and data.lightWorksWorldEmitter.orientation=="N")
local view=P.inspect(item);view.original=0
assert(P.restore(item) and item.yaw==35.5,"original field and logical orientation must survive the probe")
local once=true
item.setWorldZRotation=function(self,value)
    self.yaw=value
    if once then once=false;error("setter failed after write")end
end
assert(not P.preview(item,180) and item.yaw==35.5,"failed preview must verify rollback")
item.setWorldZRotation=function(self,value)self.yaw=value end
assert(P.preview(item,270));remove({});assert(item.yaw==270)
remove(backing);assert(item.yaw==35.5,"removal restores only the exact previewed item")
assert(P.preview(item,45))
item.setWorldZRotation=function()error("restore unavailable")end
assert(not P.restore(item) and P.inspect(item).status=="inspection_required")
assert(not P.preview(item,180),"uncertain restore cannot be overwritten by another preview")
item.setWorldZRotation=function(self,value)self.yaw=value end
assert(P.restore() and item.yaw==35.5 and not P.status().pending)
print("debug/SP rotation readback, restore, removal, failure quarantine and unchanged logical aiming pass")
