require "lightWorks/lightWorks_API"
require "lightWorks/lightWorks_Vanilla"

local lightWorks = lightWorks

local function classifyLootContext(roomType, containerType)
    local text = string.lower(tostring(roomType or "") .. " " .. tostring(containerType or ""))
    if string.find(text, "police", 1, true) then return "police" end
    if string.find(text, "military", 1, true) or string.find(text, "army", 1, true) then return "military" end
    return "default"
end

local function onFillContainer(roomType, containerType, container)
    if lightWorks.Config.EnableSpawnBulbConfiguration==false then return end
    if not container then return end

    -- B42 can pass ItemPickerJava$ItemPickerContainer for sub-container rolls.
    -- That is a distribution descriptor, not an ItemContainer, and has no
    -- inventory contents to modify. Detect it without indexing Java methods.
    local descriptor = tostring(container)
    if string.find(descriptor, "ItemPickerContainer", 1, true) then
        return
    end

    local context = classifyLootContext(roomType, containerType)

    -- Do not probe container.getItems as a field; Kahlua can throw while indexing
    -- methods on the wrong Java object. Invoke inside pcall instead.
    local okItems, items = pcall(function()
        return container:getItems()
    end)
    if not okItems or not items then return end

    local okSize, size = pcall(function() return items:size() end)
    if not okSize or not size then return end

    for i=0,size-1 do
        local okItem, item = pcall(function() return items:get(i) end)
        if okItem and item and lightWorks.isRegisteredLight(item) then
            local okMD, md = pcall(function() return item:getModData() end)
            local state = okMD and md and md[lightWorks.MODDATA_KEY] or nil

            -- Only factory-configure a light that has never had an explicit bulb state.
            if not state or not state.hasExplicitBulbState then
                local okApply, applied, bulbType = pcall(function()
                    local ok, bulb = lightWorks.applySpawnBulb(item, context)
                    return ok, bulb
                end)

                if okApply and applied then
                    print(string.format(
                        "[lightWorks] Spawn bulb: %s -> %s context=%s",
                        tostring(item:getFullType()), tostring(bulbType), tostring(context)
                    ))
                end
            end
        end
    end
end

if Events and Events.OnFillContainer then
    Events.OnFillContainer.Add(onFillContainer)
end
