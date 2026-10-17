lightWorks={}
local Access=require "lightWorks/lightWorks_ItemAccess"
local items={}
local mode="normal"
local added,removed=0,0
sendAddItemToContainer=function() added=added+1 end
sendRemoveItemFromContainer=function() removed=removed+1 end
local inventory={}
function inventory:contains(item) return items[item]==true end
function inventory:AddItem(item)
    if mode=="noop" then return item end
    items[item]=true
    if mode=="throw-after" then error("inserted") end
    return item
end
function inventory:Remove(item)
    if mode=="noop" then return end
    items[item]=nil
    if mode=="throw-after" then error("removed") end
end
local player={getInventory=function() return inventory end}
instanceItem=function(fullType)
    return {getFullType=function() return fullType end,getContainer=function() return inventory end,
        getOutermostContainer=function() return inventory end}
end
local item=assert(Access.addItem(player,"Test.Bulb"))
assert(items[item] and added==1 and Access.ownsItem(player,item))
mode="noop"
assert(not Access.removeItem(player,item) and items[item] and removed==0)
assert(not Access.addItem(player,"Test.Bulb") and added==1)
mode="throw-after"
assert(Access.removeItem(player,item) and not items[item] and removed==1)
assert(not Access.removeItem(player,item) and removed==1)
local new=assert(Access.addItem(player,"Test.Bulb"))
assert(items[new] and added==2,"actual insertion must not create a retry duplicate")
local foreign={getContainer=function() return inventory end,getOutermostContainer=function() return {} end}
items[foreign]=true
assert(not Access.removeItem(player,foreign) and items[foreign])
instanceItem=function() error("factory") end
assert(not Access.addItem(player,"Test.Bulb") and added==2)
assert(not Access.ownsItem(nil,new) and not Access.ownsItem(player,nil))
mode="normal"
assert(Access.removeItem(player,new))
new.custom="preserve exact object"
assert(Access.returnItem(player,new,inventory) and items[new] and new.custom=="preserve exact object")
assert(Access.removeItem(player,new))
mode="noop"
assert(not Access.returnItem(player,new,inventory))
local sent={}
syncItemModData=function(actor,target) assert(actor==player and target==new); sent.metadata=true end
syncItemFields=function(actor,target) assert(actor==player and target==new); sent.fields=true end
syncItemActivated=function(actor,target) assert(actor==player and target==new); sent.active=true end
assert(Access.syncServiceState(player,new) and sent.metadata and sent.fields and sent.active)
local weapon={}
sent={}
syncHandWeaponFields=function(actor,target) assert(actor==player and target==weapon); sent.weapon=true end
assert(Access.syncServiceState(player,new,weapon) and sent.weapon and not sent.metadata and not sent.fields)
syncHandWeaponFields=function() error("network") end
assert(not Access.syncServiceState(player,new,weapon))
print("lightWorks inventory no-op/throw-after/ownership transaction checks passed")

local child={};local root={}
local bag={getInventory=function()return child end}
local bulb={getFullType=function()return "Test.Nested"end}
root.getItems=function()return {size=function()return 1 end,get=function()return bag end}end
child.getItems=function()return {size=function()return 2 end,get=function(_,i)return i==0 and bulb or bag end}end
root.getAllEvalRecurse=function()error("unbounded native recursive traversal is forbidden")end
local actor={getInventory=function()return root end}
local nested=Access.inventoryItems(actor)
assert(#nested==2 and nested[2]==bulb,"bounded nested discovery must deduplicate cycles")
local count=0
root.getItems=function()return {size=function()return 999999 end,get=function()count=count+1;return {}end}end
assert(#Access.inventoryItems(actor)==Access.MAX_ITEMS and count==Access.MAX_ITEMS,"oversized inventory must stop at the read budget")

count=0
root.getItems=function()return {iterator=function()return {hasNext=function()return true end,
    next=function()count=count+1;return nil end}end}end
assert(#Access.inventoryItems(actor)==0 and count==Access.MAX_ITEMS,"an invalid iterator must not evade the read budget")
