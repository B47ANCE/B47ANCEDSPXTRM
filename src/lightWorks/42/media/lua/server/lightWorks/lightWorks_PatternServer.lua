local Patterns=require "lightWorks/lightWorks_Patterns"
local Access=require "lightWorks/lightWorks_ItemAccess"

local function finiteInteger(value)return type(value)=="number"and value==value and math.abs(value)<math.huge and value==math.floor(value)end
local function itemId(item)local ok,id=Access.call(item,"getID");return ok and id or nil end
local function resolve(player,id)
    if not finiteInteger(id)then return nil end
    local found,parent
    local function consider(item,owner)
        if itemId(item)==id then if found and found~=item then found=false else found=item;parent=owner end end
    end
    for _,item in ipairs(Access.inventoryItems(player))do
        consider(item,nil)
        for _,part in ipairs(Access.weaponParts(item))do consider(part,item)end
    end
    for _,item in ipairs(Access.attachedItems(player))do consider(item,nil)end
    return found or nil,parent
end
local function onCommand(module,command,player,args)
    if module~="lightWorks"or command~="setPattern"or type(args)~="table"or not player then return end
    if type(args.patternId)~="string"or #args.patternId>64 or type(args.operationId)~="string"or #args.operationId>128 then return end
    local item,parent=resolve(player,args.itemId);if not item or not lightWorks.isRegisteredLight(item)then return end
    local ok=Patterns.set(item,args.patternId,args.operationId);if ok then Access.syncServiceState(player,item,parent)end
end
if Events and Events.OnClientCommand then Events.OnClientCommand.Add(onCommand)end
return {resolve=resolve,onCommand=onCommand}
