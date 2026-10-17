require "lightWorks/lightWorks_API"
require "lightWorks/lightWorks_Vanilla"
require "lightWorks/lightWorks_powerWorks"
require "lightWorks/lightWorks_ChangeBulbAction"
require "TimedActions/ISTimedActionQueue"

local lightWorks = lightWorks
local Access = require "lightWorks/lightWorks_ItemAccess"

local function tr(key,fallback)
    local get=rawget(_G,"getText")
    if type(get)~="function" then return fallback end
    local ok,value=pcall(get,key)
    if ok and type(value)=="string" and value~="" and value~=key then return value end
    return fallback
end

local function profileName(profile,physicalItem)
    if not profile then return nil end
    local ok,name=Access.call(physicalItem,"getDisplayName")
    if ok and name then return name end
    local manager=rawget(_G,"ScriptManager")
    manager=manager and manager.instance or nil
    local scriptOk,script=Access.call(manager,"getItem",profile.item)
    if scriptOk and script then
        local nameOk,scriptName=Access.call(script,"getDisplayName")
        if nameOk and scriptName then return scriptName end
    end
    return tr(profile.translationKey,profile.displayName)
end

local function unwrap(entry)
    local ok, value = pcall(function()
        if not entry then return nil end
        if entry.items and entry.items[1] then return entry.items[1] end
        return entry
    end)
    return ok and value or nil
end

local function findFirstBulb(playerObj, bulbType)
    return lightWorks.findFirstInventoryItem(playerObj, bulbType)
end

local function queueInstallBulb(playerObj, lightItem, bulbType)
    if not playerObj or not lightItem or not bulbType then return end
    local canService = lightWorks.canServiceLight(playerObj, lightItem)
    if not canService then return end
    local bulbItem = findFirstBulb(playerObj, bulbType)
    if not bulbItem then return end

    ISTimedActionQueue.add(
        lightWorks.ChangeBulbAction:new(playerObj, lightItem, "install", bulbType)
    )
end

local function queueRemoveBulb(playerObj, lightItem)
    if not playerObj or not lightItem then return end
    local canService = lightWorks.canServiceLight(playerObj, lightItem)
    if not canService or not lightWorks.hasBulb(lightItem) then return end

    ISTimedActionQueue.add(
        lightWorks.ChangeBulbAction:new(playerObj, lightItem, "remove", nil)
    )
end

local function getAvailableCompatibleBulbs(playerObj, lightItem)
    local current = lightWorks.getInstalledBulbType(lightItem)
    local result = {}

    for bulbType, profile in pairs(lightWorks.Bulbs) do
        if bulbType ~= current and lightWorks.isCompatible(lightItem, bulbType) then
            local bulbItem = findFirstBulb(playerObj, bulbType)
            if bulbItem then
            result[#result+1] = {
                bulbType = bulbType,
                profile = profile,
                item = bulbItem,
            }
            end
        end
    end

    table.sort(result, function(a, b)
        return tostring(profileName(a.profile,a.item)) < tostring(profileName(b.profile,b.item))
    end)

    return result
end

local function itemTexture(item)
    local ok, texture = Access.call(item, "getTex")
    if ok and texture then return texture end
    ok, texture = Access.call(item, "getNormalTexture")
    return ok and texture or nil
end

local function typeTexture(fullType)
    local manager = rawget(_G, "ScriptManager")
    manager = manager and manager.instance or nil
    local ok, script = Access.call(manager, "getItem", fullType)
    if not ok or not script then return nil end
    ok, script = Access.call(script, "getNormalTexture")
    return ok and script or nil
end

local function applyBulbIcon(option, bulbType, physicalItem)
    if not option or not bulbType then return end
    option.iconTexture = itemTexture(physicalItem) or typeTexture(bulbType)
    local profile = lightWorks.getBulbProfile(bulbType)
    local color = profile and profile.visible and profile.visible.color or nil
    if option.iconTexture and type(color) == "table" then
        option.color = {
            r = math.max(0, math.min(1, tonumber(color.r) or 1)),
            g = math.max(0, math.min(1, tonumber(color.g) or 1)),
            b = math.max(0, math.min(1, tonumber(color.b) or 1)),
        }
    end
end

local function existingItemMenu(context, itemName)
    if not context then return nil, nil end
    local okOption, option = Access.call(context, "getOptionFromName", tostring(itemName))
    if not okOption or not option then return nil, nil end
    local okSubOption, subOption = pcall(function() return option.subOption end)
    if not okSubOption or subOption == nil then return nil, nil end
    local okMenu, menu = Access.call(context, "getSubMenu", subOption)
    if not okMenu or not menu then return nil, nil end
    return option, menu
end

local function addBulbOptions(playerNum, context, rawItems)
    local playerObj = getSpecificPlayer(playerNum)
    if not playerObj then return end

    local selectedLight = nil
    if type(rawItems) ~= "table" then return end
    for _, entry in ipairs(rawItems) do
        local item = unwrap(entry)
        if item and lightWorks.isRegisteredLight(item) then
            selectedLight = item
            break
        end
    end
    if not selectedLight then return end

    -- Keep context menus clean: if the player lacks any accepted maintenance
    -- tool, lightWorks exposes no bulb service actions at all.
    local canService = lightWorks.canServiceLight(playerObj, selectedLight)
    if not canService then return end

    local availableBulbs = getAvailableCompatibleBulbs(playerObj, selectedLight)
    local currentBulb = lightWorks.getInstalledBulbType(selectedLight)
    local hasRemovableBulb = currentBulb ~= nil
    if #availableBulbs == 0 and not hasRemovableBulb then return end

    -- Keep all servicing below the selected light's own menu. This leaves the
    -- root inventory menu clean and gives future power/repair actions one stable
    -- item-owned home without duplicating compatibility checks.
    local _, itemName = Access.call(selectedLight, "getDisplayName")
    if not itemName then _, itemName = Access.call(selectedLight, "getName") end
    itemName = itemName or (lightWorks.getLightProfile(selectedLight).displayName) or Access.fullType(selectedLight) or "Light"
    local itemOption, itemMenu = existingItemMenu(context, itemName)
    if not itemMenu then
        itemOption = context:addOption(tostring(itemName), selectedLight, nil)
        itemMenu = ISContextMenu:getNew(context)
        context:addSubMenu(itemOption, itemMenu)
    end
    if itemOption and not itemOption.iconTexture then
        itemOption.iconTexture = itemTexture(selectedLight)
    end

    if #availableBulbs > 0 then
        local rootOption = itemMenu:addOption(tr("ContextMenu_lightWorks_ChangeBulb","Change Bulb"), selectedLight, nil)
        applyBulbIcon(rootOption, currentBulb, nil)
        local sub = ISContextMenu:getNew(context)
        itemMenu:addSubMenu(rootOption, sub)

        for _, entry in ipairs(availableBulbs) do
            local bulbOption = sub:addOption(
                profileName(entry.profile,entry.item),
                playerObj,
                queueInstallBulb,
                selectedLight,
                entry.bulbType
            )
            applyBulbIcon(bulbOption, entry.bulbType, entry.item)
        end

    end
    if hasRemovableBulb then
        local removeOption = itemMenu:addOption(tr("ContextMenu_lightWorks_RemoveBulb","Remove Bulb"), playerObj, queueRemoveBulb, selectedLight)
        applyBulbIcon(removeOption, currentBulb, nil)
    end
end

local contextErrorReported = false

local function safeAddBulbOptions(playerNum, context, rawItems)
    local ok, err = pcall(addBulbOptions, playerNum, context, rawItems)
    if not ok then
        -- Never allow a lightWorks integration error to break the vanilla inventory
        -- context menu. Log the first failure clearly for diagnosis.
        if not contextErrorReported then
            contextErrorReported = true
            print("[lightWorks] Context-menu integration error: " .. tostring(err))
        end
    end
end

Events.OnFillInventoryObjectContextMenu.Add(safeAddBulbOptions)
