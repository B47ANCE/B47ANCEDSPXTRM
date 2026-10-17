lightWorks = lightWorks or {}
local lightWorks = lightWorks

lightWorks.ItemAccess = lightWorks.ItemAccess or {}
local Access = lightWorks.ItemAccess
Access.MAX_ITEMS=1024
Access.MAX_CONTAINERS=64
local unpackArgs = unpack or table.unpack

function Access.call(object, methodName, ...)
    if not object or type(methodName) ~= "string" then return false, nil end
    local args = { ... }
    local okMethod, method = pcall(function() return object[methodName] end)
    if not okMethod or type(method) ~= "function" then return false, nil end
    return pcall(method, object, unpackArgs(args))
end

function Access.fullType(itemOrType)
    if type(itemOrType) == "string" then return itemOrType end
    local ok, value = Access.call(itemOrType, "getFullType")
    return ok and type(value) == "string" and value or nil
end

function Access.inventory(playerObj)
    local ok, value = Access.call(playerObj, "getInventory")
    return ok and value or nil
end

function Access.modData(item)
    local ok, value = Access.call(item, "getModData")
    return ok and value or nil
end

local function appendJavaList(out, list, limit)
    if not list then return end
    limit=limit or Access.MAX_ITEMS
    local okIterator, iterator = Access.call(list, "iterator")
    if okIterator and iterator then
        for _=1,math.max(0,limit-#out) do
            local okHas, has = Access.call(iterator, "hasNext")
            if not okHas or not has then break end
            local okNext, value = Access.call(iterator, "next")
            if okNext and value then out[#out + 1] = value end
        end
        return
    end
    local okSize, size = Access.call(list, "size")
    if not okSize or type(size) ~= "number" then return end
    for i = 0, math.min(size,limit-#out) - 1 do
        local okGet, value = Access.call(list, "get", i)
        if okGet and value then out[#out + 1] = value end
    end
end

function Access.inventoryItems(playerObj)
    local out = {}
    local inv = Access.inventory(playerObj)
    if not inv then return out end
    -- Explicit breadth-first discovery bounds both native list reads and nested
    -- containers. Never ask the engine to traverse the entire inventory first.
    local queue,seen,items={inv},{[inv]=true},{}
    local cursor=1
    while cursor<=#queue and cursor<=Access.MAX_CONTAINERS and #out<Access.MAX_ITEMS do
        local container=queue[cursor];cursor=cursor+1
        local ok,list=Access.call(container,"getItems")
        local found={};if ok then appendJavaList(found,list,Access.MAX_ITEMS-#out) end
        for _,item in ipairs(found) do
            if not items[item] then
                items[item]=true;out[#out+1]=item
                local got,nested=Access.call(item,"getInventory")
                if got and nested and not seen[nested] and #queue<Access.MAX_CONTAINERS then
                    seen[nested]=true;queue[#queue+1]=nested
                end
                if #out>=Access.MAX_ITEMS then break end
            end
        end
    end
    return out
end

function Access.attachedItems(playerObj)
    local out = {}
    local ok, list = Access.call(playerObj, "getAttachedItems")
    if ok then appendJavaList(out, list,64) end
    for index,entry in ipairs(out) do
        local wrapped,item=Access.call(entry,"getItem")
        if wrapped and item then out[index]=item end
    end
    return out
end

function Access.weaponParts(item)
    local out = {}
    local ok, list = Access.call(item, "getAllWeaponParts")
    if ok then appendJavaList(out, list,32) end
    return out
end

function Access.addItem(playerObj, fullType)
    local inv = Access.inventory(playerObj)
    if not inv or type(fullType)~="string" then return nil end
    -- Retain the exact object even if AddItem inserts it and then throws.
    local made,item=pcall(function() return instanceItem(fullType) end)
    if not made or not item then return nil end
    Access.call(inv,"AddItem",item)
    local checked,present=Access.call(inv,"contains",item)
    if not checked then return nil,"uncertain" end
    if present~=true then return nil,"not_inserted" end
    if sendAddItemToContainer then pcall(sendAddItemToContainer, inv, item) end
    return item
end

function Access.ownsInventoryItem(playerObj,item)
    local inventory=Access.inventory(playerObj)
    if not inventory or not item then return false end
    local _,outer=Access.call(item,"getOutermostContainer")
    local _,container=Access.call(item,"getContainer")
    local _,present=Access.call(container,"contains",item)
    return outer==inventory and present==true
end

function Access.findWeaponForPart(playerObj,item)
    if not item then return nil end
    if Access.ownsInventoryItem(playerObj,item) then return nil end
    -- Installed weapon parts may have no container of their own. Ownership is
    -- established through a carried weapon, never through a nearby world scan.
    for _,weapon in ipairs(Access.inventoryItems(playerObj)) do
        for _,part in ipairs(Access.weaponParts(weapon)) do
            if part==item and Access.ownsInventoryItem(playerObj,weapon) then
                local ok,id=Access.call(part,"getID")
                if ok and type(id)=="number" and math.abs(id)<math.huge and id==math.floor(id) then return weapon,id end
            end
        end
    end
    return nil
end

function Access.resolveWeaponPart(playerObj,weapon,id)
    if type(id)~="number" or math.abs(id)==math.huge or id~=math.floor(id) or not Access.ownsInventoryItem(playerObj,weapon) then return nil end
    local found=nil
    for _,part in ipairs(Access.weaponParts(weapon)) do
        local ok,partId=Access.call(part,"getID")
        if ok and partId==id then
            if found then return nil end -- ambiguous/corrupt identity fails closed
            found=part
        end
    end
    return found
end

function Access.ownsItem(playerObj,item)
    return Access.ownsInventoryItem(playerObj,item) or Access.findWeaponForPart(playerObj,item)~=nil
end

function Access.removeItem(playerObj, item)
    if not Access.ownsItem(playerObj,item) then return false end
    local okContainer, container = Access.call(item, "getContainer")
    if not okContainer or not container then return false end
    Access.call(playerObj, "removeFromHands", item)
    Access.call(container, "Remove", item)
    local checked,present=Access.call(container,"contains",item)
    if not checked then return false,"uncertain" end
    if present~=false then return false,"not_removed" end
    if sendRemoveItemFromContainer then pcall(sendRemoveItemFromContainer, container, item) end
    return true
end

function Access.returnItem(playerObj,item,container)
    if not item or not container then return false end
    local _,present=Access.call(container,"contains",item)
    if present~=true then Access.call(container,"AddItem",item) end
    local checked,restored=Access.call(container,"contains",item)
    if not checked or restored~=true then return false end
    if sendAddItemToContainer then pcall(sendAddItemToContainer,container,item) end
    return true
end

function Access.syncServiceState(playerObj,item,parentWeapon)
    local function send(name,target)
        local fn=rawget(_G,name)
        if type(fn)~="function" then return false end
        return pcall(fn,playerObj,target)
    end
    if parentWeapon then
        -- This native packet serializes the weapon's full attachment items,
        -- including their ModData. A containerless part cannot use item sync.
        return send("syncHandWeaponFields",parentWeapon)
    end
    local metadata=send("syncItemModData",item)
    local fields=send("syncItemFields",item)
    local active=send("syncItemActivated",item)
    return metadata and fields and active
end

return Access
