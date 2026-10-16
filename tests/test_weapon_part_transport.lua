unpack=unpack or table.unpack
lightWorks={getRemoveBulbTime=function() return 10 end,getChangeBulbTime=function() return 20 end,
    canServiceLight=function() return true end,hasBulb=function() return true end}
package.loaded["lightWorks/lightWorks_API"]=lightWorks
package.loaded["TimedActions/ISBaseTimedAction"]=true
ISBaseTimedAction={derive=function(_,name)
    local class={Type=name}; class.__index=class; return setmetatable(class,{__index=ISBaseTimedAction})
end,new=function(class,character) return setmetatable({character=character},class) end}
local function list(values) return {size=function() return #values end,get=function(_,i) return values[i+1] end} end
local carried,parts={},{}
local inventory={getItems=function() return list(carried) end}
local owner=inventory
local present=true
local bag={contains=function() return present end}
local weapon={getContainer=function() return bag end,getOutermostContainer=function() return owner end,
    getAllWeaponParts=function() return list(parts) end}
local partData={}
local part={getID=function() return 42 end,getModData=function() return partData end}
local replacement={getID=function() return 43 end}
parts={part}; carried={weapon}
local player={getInventory=function() return inventory end,isDead=function() return false end}
local Access=require "lightWorks/lightWorks_ItemAccess"
require "lightWorks/lightWorks_ChangeBulbAction"
local Action=lightWorks.ChangeBulbAction
local localAction=Action:new(player,part,"remove")
assert(localAction.targetItem==nil and localAction.parentWeapon==weapon and localAction.partId==42)
assert(localAction.lightItem==part and localAction:isValid())
-- Mirrors the native constructor-name payload, not a copy of runtime fields.
local restored=Action:new(localAction.character,localAction.targetItem,localAction.mode,
    localAction.bulbType,localAction.parentWeapon,localAction.partId)
assert(restored.lightItem==part and restored:isValid())
parts={replacement}; assert(not restored:isValid())
assert(not Action:new(player,nil,"remove",nil,weapon,42):isValid())
parts={part}; owner={}; assert(not restored:isValid()); owner=inventory
present=false; assert(not restored:isValid()); present=true
parts={part,part}; assert(not Access.resolveWeaponPart(player,weapon,42))
parts={part}; assert(not Action:new(player,nil,"remove",nil,nil,42):isValid())
assert(not Access.resolveWeaponPart(player,weapon,"42"))
assert(not Access.resolveWeaponPart(player,weapon,0/0))
assert(Access.ownsItem(player,part))
carried={}; assert(not Access.ownsItem(player,part))
print("lightWorks parent-weapon payload reconstruction and stale-part rejection checks passed")
