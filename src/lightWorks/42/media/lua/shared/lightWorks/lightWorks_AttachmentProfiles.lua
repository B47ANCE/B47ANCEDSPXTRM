require "lightWorks/lightWorks_API"
local lightWorks = lightWorks
local Access = require "lightWorks/lightWorks_ItemAccess"

lightWorks.ATTACHMENT_TYPES = {
    DOWN = "lightWorks_BeltDownLight",
    ANGLE = "lightWorks_AngleLight",
}
lightWorks.ATTACHMENT_TYPE = lightWorks.ATTACHMENT_TYPES.DOWN

local function scriptItem(fullType)
    local manager = rawget(_G, "ScriptManager")
    manager = manager and manager.instance or nil
    local ok, item = Access.call(manager, "getItem", fullType)
    return ok and item or nil
end

function lightWorks.applyAttachmentProfiles()
    local result = { patched = 0, skipped = 0 }
    for fullType, profile in pairs(lightWorks.Lights) do
        local attachment = profile.attachment
        if attachment and attachment.belt == true then
            local script = scriptItem(fullType)
            if script then
                local okType = Access.call(script, "DoParam", "AttachmentType = " .. (attachment.type or lightWorks.ATTACHMENT_TYPE))
                local okModel = true
                if attachment.staticModel then
                    okModel = Access.call(script, "DoParam", "StaticModel = " .. attachment.staticModel)
                end
                if okType and okModel then result.patched = result.patched + 1 else result.skipped = result.skipped + 1 end
            else
                result.skipped = result.skipped + 1
            end
        end
    end
    return result
end

function lightWorks.migrateOwnedLightAttachments(playerObj)
    local changed = 0
    for _, item in ipairs(lightWorks.collectPlayerLights(playerObj)) do
        local profile = lightWorks.getLightProfile(item)
        local attachment = profile and profile.attachment or nil
        if attachment and attachment.belt == true then
            local desired = attachment.type or lightWorks.ATTACHMENT_TYPE
            local _, current = Access.call(item, "getAttachmentType")
            if current ~= desired then
                local ok = Access.call(item, "setAttachmentType", desired)
                if ok then changed = changed + 1 end
            end
        elseif not attachment then
            local _, current = Access.call(item, "getAttachmentType")
            if current == "lightWorks_BeltLight" or current == lightWorks.ATTACHMENT_TYPES.DOWN or current == lightWorks.ATTACHMENT_TYPES.ANGLE then
                local attached = playerObj and playerObj.getAttachedItems and playerObj:getAttachedItems() or nil
                local location = attached and attached.getLocation and attached:getLocation(item) or nil
                if location and playerObj.setAttachedItem then pcall(function() playerObj:setAttachedItem(location,nil) end) end
                local okClear = pcall(function() item:setAttachmentType(nil) end)
                if okClear then changed = changed + 1 end
            end
        end
    end
    return changed
end

local function applySafely()
    local ok, result = pcall(lightWorks.applyAttachmentProfiles)
    if not ok then print("[lightWorks] Attachment profile error: " .. tostring(result)) end
end

if Events then
    if Events.OnInitGlobalModData then Events.OnInitGlobalModData.Add(applySafely) end
    if Events.OnInitWorld then Events.OnInitWorld.Add(applySafely) end
end

return lightWorks
