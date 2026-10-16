unpack=unpack or table.unpack
package.loaded["TimedActions/ISBaseTimedAction"]=true
ISBaseTimedAction={derive=function(_,name)
    local class={Type=name}; class.__index=class; return setmetatable(class,{__index=ISBaseTimedAction})
end,new=function(class,character) return setmetatable({character=character},class) end,perform=function() end}
local dead=false
local character={isDead=function() return dead end}
local light,bulb={},{}
local data={}
local owned,tool,available=true,true,true
local installed="white"
local writes=0
lightWorks={canServiceLight=function() return tool end,findFirstInventoryItem=function() return available and bulb end,
    captureServiceState=function() return {installed=installed} end,
    restoreServiceState=function(_,snapshot) installed=snapshot.installed; return true end,
    isCompatible=function() return true end,hasBulb=function() return installed~=nil end,
    getRemoveBulbTime=function() return 10 end,getChangeBulbTime=function() return 20 end,
    installBulb=function(_,kind) local old=installed; installed=kind; writes=writes+1; return true,old end,
    removeBulb=function() local old=installed; installed=nil; writes=writes+1; return true,old end}
package.loaded["lightWorks/lightWorks_API"]=lightWorks
local Access={syncServiceState=function() return true end,modData=function(item) return item==light and data or nil end,findWeaponForPart=function() return nil end,ownsItem=function() return owned end,call=function(object,method,...)
    if not object or not object[method] then return false end
    return pcall(object[method],object,...)
end,removeItem=function() available=false; return true end,addItem=function() return {} end,
returnItem=function() available=true; return true end}
package.loaded["lightWorks/lightWorks_ItemAccess"]=Access
local Action=require "lightWorks/lightWorks_ChangeBulbAction"
Action=lightWorks.ChangeBulbAction
assert(_G[Action.Type]==Action)
local action=Action:new(character,light,"install","violet")
action:perform(); assert(writes==0)
isClient=function() return true end
assert(not action:complete() and writes==0)
isClient=function() return false end
owned=false; assert(not action:complete()); owned=true
tool=false; assert(not action:complete()); tool=true
dead=true; assert(not action:complete()); dead=false
available=false; assert(not action:complete()); available=true
assert(action:complete() and installed=="violet" and writes==1)
assert(not action:complete() and writes==1)
assert(Action:new(character,light,"remove"):complete() and installed==nil and writes==2)
assert(not Action:new(character,light,"remove"):complete())
assert(not Action:new(nil,nil,"install","violet"):complete())
assert(not Action:new(character,light,"invalid"):complete())
available=true; installed="white"
Access.addItem=function() return nil end
local failed=Action:new(character,light,"install","violet")
assert(not failed:complete() and installed=="white")
local count=writes
assert(not failed:complete() and writes==count)
assert(data.lightWorksServiceRecovery==nil,"verified rollback must unlock the light")
available=true
Access.addItem=function()
    assert(not Action:new(character,light,"remove"):complete(),"nested completion must not overlap")
    return {}
end
assert(Action:new(character,light,"install","violet"):complete())
assert(data.lightWorksServiceRecovery==nil)
available=true; installed="white"
Access.addItem=function() return nil,"uncertain" end
assert(not Action:new(character,light,"install","violet"):complete())
assert(data.lightWorksServiceRecovery.status=="inspection_required")
assert(installed=="violet","unknown output presence must not be followed by speculative rollback")
assert(not Action:new(character,light,"remove"):isValid())
assert(not Action:new(character,light,"remove"):complete(),"fresh action must honor persisted marker")
data.lightWorksServiceRecovery=nil -- fixture repair, not a production auto-clear
available=true; installed="white"
Access.addItem=function() return nil end
Access.returnItem=function() return false end
assert(not Action:new(character,light,"install","violet"):complete())
assert(data.lightWorksServiceRecovery.status=="inspection_required","failed item recovery stays locked")
print("lightWorks authoritative bulb action and completion revalidation checks passed")
