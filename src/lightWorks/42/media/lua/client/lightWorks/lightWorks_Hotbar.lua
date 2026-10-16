pcall(require, "Hotbar/ISHotbarAttachDefinition")
require "lightWorks/lightWorks_AttachmentProfiles"

local lightWorks = lightWorks
local SLOT_TARGETS = {
    SmallBeltLeft = {target="Belt Left",types={lightWorks.ATTACHMENT_TYPES.DOWN,lightWorks.ATTACHMENT_TYPES.ANGLE}},
    FrontBeltL = {target="Belt Left",types={lightWorks.ATTACHMENT_TYPES.DOWN,lightWorks.ATTACHMENT_TYPES.ANGLE}},
    SmallBeltRight = {target="Belt Right",types={lightWorks.ATTACHMENT_TYPES.DOWN,lightWorks.ATTACHMENT_TYPES.ANGLE}},
    FrontBeltR = {target="Belt Right",types={lightWorks.ATTACHMENT_TYPES.DOWN,lightWorks.ATTACHMENT_TYPES.ANGLE}},
    WebbingLeft = {target="Webbing Left Walkie",types={lightWorks.ATTACHMENT_TYPES.ANGLE}},
    WebbingRight = {target="Webbing Right Walkie",types={lightWorks.ATTACHMENT_TYPES.ANGLE}},
}

local function registerSlots()
    if type(ISHotbarAttachDefinition) ~= "table" then return end
    for _, definition in ipairs(ISHotbarAttachDefinition) do
        local slot = definition and SLOT_TARGETS[definition.type] or nil
        if slot then
            definition.attachments = definition.attachments or {}
            definition.attachments["lightWorks_BeltLight"] = nil
            for _, attachmentType in ipairs(slot.types) do
                definition.attachments[attachmentType] = slot.target
            end
        end
    end
end

local function migratePlayer(playerNum, playerObj)
    if not playerObj and getSpecificPlayer then playerObj = getSpecificPlayer(playerNum or 0) end
    if not playerObj then return end
    pcall(lightWorks.migrateOwnedLightAttachments, playerObj)
end

local function initialize()
    registerSlots()
    pcall(lightWorks.applyAttachmentProfiles)
    local count = getNumActivePlayers and getNumActivePlayers() or 1
    for playerNum = 0, math.max(0, count - 1) do migratePlayer(playerNum) end
end

if Events then
    if Events.OnCreatePlayer then Events.OnCreatePlayer.Add(migratePlayer) end
    if Events.OnGameStart then Events.OnGameStart.Add(initialize) end
end

registerSlots()
