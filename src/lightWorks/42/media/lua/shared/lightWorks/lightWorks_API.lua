lightWorks = lightWorks or {}
local lightWorks = lightWorks
local Access = require "lightWorks/lightWorks_ItemAccess"

lightWorks.VERSION = "0.25.3"
lightWorks.MODDATA_KEY = "lightWorks"
-- UV is a mechanical emission with one canonical visible representation.
-- Emitter profiles still control strength, reach, cone geometry and falloff.
-- Reassert this value on every load. A downstream registration must not leave
-- a stale per-session UV hue behind in the shared namespace.
lightWorks.UV_VISIBLE_COLOR = { r = 0.00, g = 0.00, b = 1.00 }
lightWorks.Bulbs = lightWorks.Bulbs or {}
lightWorks.Lights = lightWorks.Lights or {}
lightWorks.SpawnBulbWeights = lightWorks.SpawnBulbWeights or {}
lightWorks.VerifiedLights = lightWorks.VerifiedLights or {}
lightWorks.LightCompatibilityProviders = lightWorks.LightCompatibilityProviders or {}

lightWorks.Config = lightWorks.Config or {
    EnableBurnout = true,
    -- Framework fallback lifetime for inventory-light bulbs. Vanilla fixtures keep
    -- their native IsoLightSwitch burnout logic; these values only govern handheld
    -- and weapon lights.
    DefaultLifetimeMinutes = 60000, -- 1000 in-game hours
    BurnedBulbItem = "Base.LightBulbBroken",
    BurnoutCheckEveryGameMinutes = 1.0,
    BulbLifetimeMultiplier = 1.0,
    ServiceTimeMultiplier = 1.0,
    RequireServiceTools = true,
    EnableAutomaticDiscovery = true,
    EnableColoredLightRenderer = true,
    EnableAttachmentGeometry = true,
    EnableSpawnBulbConfiguration = true,
    EnableSunburn = true,
    SunburnDoseMultiplier = 1.0,
    SunburnFirstDegreeDoseHours = 0.75,
    SunburnMaximumDoseHours = 4.0,
    SunburnRecoveryDoseHoursPerHour = 0.10,
    EnableLowBatteryFlicker = true,
    LowBatteryFlickerThreshold = 0.10,
    LowBatteryFlickerPeriodMs = 4000,
    LowBatteryFlickerMinimumOffFraction = 0.08,
    LowBatteryFlickerMaximumOffFraction = 0.55,
    EnableLightPatterns = true,
    EnableWorldEmitters = true,

    -- Default maintenance tools. A player needs at least ONE accepted tool
    -- to change or remove a bulb from a registered light.
    DefaultBulbTools = {
        "Base.Screwdriver",
        "Base.Pliers",
        "Base.ViseGrips",
        "Base.Multitool",
    },

    -- Timed-action work duration (PZ timed-action units).
    -- Removal and installation are independent operations.
    DefaultHandRemoveBulbTime = 35,
    DefaultHandInstallBulbTime = 45,
    DefaultToolRemoveBulbTime = 80,
    DefaultToolInstallBulbTime = 100,
}

local SANDBOX_CONFIG_KEYS = {
    "EnableBurnout", "BulbLifetimeMultiplier", "ServiceTimeMultiplier",
    "RequireServiceTools", "EnableAutomaticDiscovery", "EnableColoredLightRenderer",
    "EnableAttachmentGeometry", "EnableSpawnBulbConfiguration", "EnableSunburn",
    "SunburnDoseMultiplier", "SunburnFirstDegreeDoseHours", "SunburnMaximumDoseHours",
    "SunburnRecoveryDoseHoursPerHour",
    "EnableLowBatteryFlicker", "LowBatteryFlickerThreshold", "LowBatteryFlickerPeriodMs",
    "LowBatteryFlickerMinimumOffFraction", "LowBatteryFlickerMaximumOffFraction",
    "EnableLightPatterns", "EnableWorldEmitters",
}
function lightWorks.applySandbox()
    local root=rawget(_G,"SandboxVars")
    local values=root and root.lightWorks or nil
    if not values then return false end
    for _,key in ipairs(SANDBOX_CONFIG_KEYS) do
        if values[key]~=nil then lightWorks.Config[key]=values[key] end
    end
    return true
end
lightWorks.applySandbox()
if Events and Events.OnGameStart then Events.OnGameStart.Add(lightWorks.applySandbox) end
if Events and Events.OnServerStarted then Events.OnServerStarted.Add(lightWorks.applySandbox) end

local function copyTable(src, seen)
    if type(src) ~= "table" then return src end
    seen = seen or {}
    if seen[src] then return seen[src] end
    local out = {}
    seen[src] = out
    for k,v in pairs(src) do out[copyTable(k, seen)] = copyTable(v, seen) end
    return out
end

local function fullType(itemOrType)
    return Access.fullType(itemOrType)
end

function lightWorks.registerBulb(def)
    assert(type(def) == "table", "registerBulb expects a table")
    assert(type(def.item) == "string", "bulb.item is required")

    local profile = copyTable(def)
    profile.item = def.item
    profile.displayName = def.displayName or def.item
    profile.tags = copyTable(def.tags or {})
    profile.visible = copyTable(def.visible or {})
    profile.detection = copyTable(def.detection or {})
    profile.emissions = copyTable(def.emissions or {})
    profile.custom = copyTable(def.custom or {})
    profile.burnout = copyTable(def.burnout or {})

    -- Keep all UV-capable bulbs visually consistent regardless of their source
    -- mod or output class. UV intensity/range remain in emissions.UV and device
    -- geometry remains owned by the compatible-light emitter profile.
    if profile.tags.UV == true or profile.emissions.UV ~= nil then
        profile.visible.color = copyTable(lightWorks.UV_VISIBLE_COLOR)
    end

    lightWorks.Bulbs[profile.item] = profile
    return profile
end

-- Repeat UV normalization immediately before rendering. This prevents late
-- profile mutation or compatibility providers from producing device-specific
-- UV hues while preserving each emitter's strength, range and geometry.
function lightWorks.getRenderedVisibleColor(bulbOrType)
    local profile = type(bulbOrType)=="table" and bulbOrType or lightWorks.getBulbProfile(bulbOrType)
    if not profile then return nil end
    if (profile.tags and profile.tags.UV==true) or (profile.emissions and profile.emissions.UV~=nil) then
        return copyTable(lightWorks.UV_VISIBLE_COLOR)
    end
    return profile.visible and copyTable(profile.visible.color) or nil
end

function lightWorks.registerLight(def)
    assert(type(def) == "table", "registerLight expects a table")
    assert(type(def.item) == "string", "light.item is required")

    local profile = copyTable(def)
    profile.item = def.item
    profile.defaultBulb = def.defaultBulb or "Base.LightBulb"
    profile.displayName = def.displayName
    profile.accepts = def.accepts -- optional callback(lightItem, bulbProfile) -> bool
    -- Optional wearable-light capability. Compatibility patches describe the
    -- verified light here; the hotbar bridge owns slot integration globally.
    profile.attachment = def.attachment and copyTable(def.attachment) or nil
    -- Registered lights participate in dropped/placed world emission by
    -- default. Exact compatibility providers can explicitly opt out when a
    -- backing item cannot safely remain active outside inventory.
    profile.supportsWorldEmission = def.supportsWorldEmission ~= false
    -- powerWorks capability. AA + vanilla compatibility is the safe
    -- portable-light default; verified providers can declare another form
    -- factor for otherwise-unspecified verified portable lights.
    profile.power = copyTable(def.power or { sizes={"AA","LEGACY"}, drainMultiplier=1.0 })

    -- Optional accepted maintenance tools. If omitted, framework defaults
    -- to screwdriver OR pliers. Set tools = false to disable tool requirement.
    if def.tools == false then
        profile.tools = false
    elseif def.tools ~= nil then
        profile.tools = copyTable(def.tools)
        for index, tool in ipairs(profile.tools) do
            assert(type(tool) == "string" and tool ~= "", "light.tools[" .. index .. "] must be an item type")
        end
    else
        profile.tools = copyTable(lightWorks.Config.DefaultBulbTools)
    end

    -- Per-light remove/install durations. Replacing a bulb derives its total
    -- automatically: remove time (only if a bulb is installed) + install time.
    if profile.tools == false then
        profile.removeBulbTime = tonumber(def.removeBulbTime) or lightWorks.Config.DefaultHandRemoveBulbTime
        profile.installBulbTime = tonumber(def.installBulbTime) or lightWorks.Config.DefaultHandInstallBulbTime
    else
        profile.removeBulbTime = tonumber(def.removeBulbTime) or lightWorks.Config.DefaultToolRemoveBulbTime
        profile.installBulbTime = tonumber(def.installBulbTime) or lightWorks.Config.DefaultToolInstallBulbTime
    end

    lightWorks.Lights[profile.item] = profile
    return profile
end

-- Human-reviewed compatibility authority. Discovery suggestions never call this
-- automatically; core or compatibility mods register exact reviewed entries.
function lightWorks.registerLightCompatibilityProvider(def)
    assert(type(def)=="table" and type(def.id)=="string" and def.id~="","provider id is required")
    assert(not lightWorks.LightCompatibilityProviders[def.id],"duplicate light compatibility provider: "..def.id)
    local provider=copyTable(def)
    provider.displayName=provider.displayName or provider.id
    provider.kind=provider.kind or "patch"
    provider.verified=provider.verified~=false
    lightWorks.LightCompatibilityProviders[provider.id]=provider
    return provider
end

function lightWorks.registerVerifiedLight(providerId, def)
    assert(type(providerId) == "string" and providerId ~= "", "providerId is required")
    assert(type(def) == "table" and type(def.item) == "string", "verified light definition is required")
    local provider=lightWorks.LightCompatibilityProviders[providerId]
    assert(provider,"unknown light compatibility provider: "..providerId)
    local verified = copyTable(def)
    verified.providerId = providerId
    verified.providerName = provider.displayName
    verified.targetModId = provider.targetModId
    verified.verified = provider.verified == true
    lightWorks.VerifiedLights[verified.item] = verified
    local registered=lightWorks.registerLight(verified)
    local catalog=lightWorks.LightCatalog
    local entry=catalog and catalog.entries and catalog.entries[verified.item] or nil
    if entry then
        entry.verified=true
        entry.classification.status="verified"
        entry.classification.confidence=1.0
    end
    return registered
end

function lightWorks.getLightCompatibilityProvider(providerId)
    return lightWorks.LightCompatibilityProviders[providerId]
end

function lightWorks.getVerifiedLight(itemOrType)
    return lightWorks.VerifiedLights[fullType(itemOrType)]
end

function lightWorks.getBulbProfile(itemOrType)
    return lightWorks.Bulbs[fullType(itemOrType)]
end

function lightWorks.getLightProfile(itemOrType)
    return lightWorks.Lights[fullType(itemOrType)]
end

function lightWorks.getOpticalProfile(itemOrType)
    local profile=lightWorks.getLightProfile(itemOrType)
    return profile and profile.physical or nil
end

function lightWorks.getEmitterTechnology(itemOrType)
    local profile=lightWorks.getLightProfile(itemOrType)
    return profile and profile.emitter and profile.emitter.technology or nil
end

function lightWorks.isRegisteredBulb(itemOrType)
    return lightWorks.getBulbProfile(itemOrType) ~= nil
end

function lightWorks.isRegisteredLight(itemOrType)
    return lightWorks.getLightProfile(itemOrType) ~= nil
end

function lightWorks.supportsWorldEmission(itemOrType)
    local profile=lightWorks.getLightProfile(itemOrType)
    return profile~=nil and profile.supportsWorldEmission~=false
end



function lightWorks.getRemoveBulbTime(lightItemOrType)
    local light = lightWorks.getLightProfile(lightItemOrType)
    if not light then return 0 end
    return math.max(1, (tonumber(light.removeBulbTime) or lightWorks.Config.DefaultToolRemoveBulbTime)
        * math.max(0.01,tonumber(lightWorks.Config.ServiceTimeMultiplier) or 1.0))
end

function lightWorks.getInstallBulbTime(lightItemOrType)
    local light = lightWorks.getLightProfile(lightItemOrType)
    if not light then return 0 end
    return math.max(1, (tonumber(light.installBulbTime) or lightWorks.Config.DefaultToolInstallBulbTime)
        * math.max(0.01,tonumber(lightWorks.Config.ServiceTimeMultiplier) or 1.0))
end

function lightWorks.getChangeBulbTime(lightItem)
    if not lightWorks.isRegisteredLight(lightItem) then return 0 end
    local total = lightWorks.getInstallBulbTime(lightItem)
    if lightWorks.hasBulb(lightItem) then
        total = total + lightWorks.getRemoveBulbTime(lightItem)
    end
    return math.max(1, total)
end

function lightWorks.getRequiredTools(lightItemOrType)
    local light = lightWorks.getLightProfile(lightItemOrType)
    if not light then return nil end
    return light.tools
end

function lightWorks.requiresTool(lightItemOrType)
    local tools = lightWorks.getRequiredTools(lightItemOrType)
    if tools == false or type(tools) ~= "table" then return false end
    for _ in pairs(tools) do return true end
    return false
end

-- B42 inventory helpers.
-- Use ItemContainer's native recursive APIs rather than manually traversing Java
-- inventory objects from Lua. This avoids Kahlua method/index failures when a
-- nested inventory object exposes a different Java surface than expected.
function lightWorks.inventoryContainsType(playerObj, fullType)
    if not playerObj or not fullType then return false end

    local okInv, inv = pcall(function() return playerObj:getInventory() end)
    if not okInv or not inv then return false end

    local okContains, contains = pcall(function()
        return inv:containsTypeRecurse(fullType)
    end)
    return okContains and contains == true
end

function lightWorks.findFirstInventoryItem(playerObj, fullType)
    if not playerObj or not fullType then return nil end

    local okInv, inv = pcall(function() return playerObj:getInventory() end)
    if not okInv or not inv then return nil end

    -- B42 ItemContainer:getItemFromType(type, ignoreBroken, includeInv)
    -- includeInv=true searches nested inventory containers.
    local okItem, item = pcall(function()
        return inv:getItemFromType(fullType, false, true)
    end)
    if okItem and item then return item end

    -- Conservative root-container fallback. This is intentionally non-recursive:
    -- the native recursive path above owns recursion.
    local okFind, rootItem = pcall(function()
        return inv:FindAndReturn(fullType)
    end)
    if okFind then return rootItem end

    return nil
end

-- All registered lights owned by a player, including nested inventory,
-- attachment slots, and weapon parts. This is the single bounded collection
-- path used by background lightWorks systems; it never scans the world.
function lightWorks.collectPlayerLights(playerObj)
    local result, seen, inspected = {}, {}, {}
    local function addLight(item)
        if item and not seen[item] and lightWorks.isRegisteredLight(item) then
            seen[item] = true
            result[#result + 1] = item
        end
    end
    local function inspect(item)
        if not item or inspected[item] then return end
        inspected[item] = true
        addLight(item)
        for _, part in ipairs(Access.weaponParts(item)) do addLight(part) end
    end
    local _, primary = Access.call(playerObj, "getPrimaryHandItem")
    local _, secondary = Access.call(playerObj, "getSecondaryHandItem")
    inspect(primary); inspect(secondary)
    for _, item in ipairs(Access.inventoryItems(playerObj)) do inspect(item) end
    for _, item in ipairs(Access.attachedItems(playerObj)) do inspect(item) end
    return result
end

function lightWorks.playerHasRequiredTool(playerObj, lightItemOrType)
    local light = lightWorks.getLightProfile(lightItemOrType)
    if not light then return false, nil end
    if lightWorks.Config.RequireServiceTools==false or light.tools == false then return true, nil end

    local tools = light.tools
    if type(tools) ~= "table" or #tools == 0 then
        return true, nil
    end

    for _, fullType in ipairs(tools) do
        if lightWorks.inventoryContainsType(playerObj, fullType) then
            return true, fullType
        end
    end

    return false, nil
end

function lightWorks.canServiceLight(playerObj, lightItem)
    if not lightWorks.isRegisteredLight(lightItem) then
        return false, nil, "not_registered_light"
    end

    local ok, toolType = lightWorks.playerHasRequiredTool(playerObj, lightItem)
    if not ok then
        return false, nil, "missing_required_tool"
    end

    return true, toolType, nil
end

function lightWorks.isCompatible(lightItem, bulbItemOrType)
    local lightProfile = lightWorks.getLightProfile(lightItem)
    local bulbProfile = lightWorks.getBulbProfile(bulbItemOrType)
    if not lightProfile or not bulbProfile then return false end
    if lightProfile.accepts then
        -- A third-party compatibility callback must not be able to take down the
        -- complete inventory context menu. Invalid callbacks fail closed.
        local ok, accepted = pcall(lightProfile.accepts, lightItem, bulbProfile)
        return ok and accepted == true
    end
    return true
end

local function stateFor(lightItem)
    if not lightItem then return nil end
    local md = Access.modData(lightItem)
    if not md then return nil end
    md[lightWorks.MODDATA_KEY] = md[lightWorks.MODDATA_KEY] or {}
    local state = md[lightWorks.MODDATA_KEY]

    -- Capture the vanilla light's original visible settings once so a regular
    -- bulb can always restore the stock flashlight behavior.
    if not state.baseVisibleCaptured then
        state.baseVisibleCaptured = true
        local getters = { LightStrength="baseLightStrength", LightDistance="baseLightDistance", TorchCone="baseTorchCone", TorchDot="baseTorchDot" }
        for suffix, key in pairs(getters) do
            local ok, value = Access.call(lightItem, "get" .. suffix)
            if ok then state[key] = value end
        end
    end
    return state
end

function lightWorks.getInstalledBulbType(lightItem)
    local lightProfile = lightWorks.getLightProfile(lightItem)
    if not lightProfile then return nil end

    if type(lightItem) == "string" then return lightProfile.defaultBulb end
    local md = Access.modData(lightItem)
    local state = md and md[lightWorks.MODDATA_KEY] or nil
    if state and state.hasExplicitBulbState then
        return state.installedBulb -- nil means physically no bulb installed
    end
    return lightProfile.defaultBulb
end

function lightWorks.hasBulb(lightItem)
    return lightWorks.getInstalledBulbType(lightItem) ~= nil
end

function lightWorks.getInstalledBulb(lightItem)
    local bulbType = lightWorks.getInstalledBulbType(lightItem)
    return bulbType and lightWorks.Bulbs[bulbType] or nil
end

function lightWorks.getBulbTag(lightItem, tag)
    local bulb = lightWorks.getInstalledBulb(lightItem)
    return bulb and bulb.tags and bulb.tags[tag] or nil
end

function lightWorks.getCustom(lightItem, key)
    local bulb = lightWorks.getInstalledBulb(lightItem)
    return bulb and bulb.custom and bulb.custom[key] or nil
end


-- Bulb-specific zombie visibility profile. 1.0 is the vanilla/white baseline.
-- This is deliberately separate from visible brightness so red tactical light can
-- remain useful to the player while being less conspicuous to AI systems that
-- consume lightWorks' visibility API.
function lightWorks.getZombieVisibilityMultiplier(lightItem)
    if not lightWorks.isRegisteredLight(lightItem) or not lightWorks.hasBulb(lightItem) then return 0.0 end
    if lightWorks.isBulbBurnedOut and lightWorks.isBulbBurnedOut(lightItem) then return 0.0 end
    local bulb = lightWorks.getInstalledBulb(lightItem)
    local detection = bulb and bulb.detection or nil
    return math.max(0.0, tonumber(detection and detection.visibilityMultiplier) or 1.0)
end

function lightWorks.getEmissionProfile(lightItem)
    if not lightWorks.isRegisteredLight(lightItem) or not lightWorks.hasBulb(lightItem) then return {} end
    if lightWorks.isBulbBurnedOut and lightWorks.isBulbBurnedOut(lightItem) then return {} end
    local bulb = lightWorks.getInstalledBulb(lightItem)
    return bulb and bulb.emissions or {}
end

function lightWorks.getEmission(lightItem, channel)
    local emissions = lightWorks.getEmissionProfile(lightItem)
    local value = emissions and emissions[channel] or nil
    if type(value) == "number" then
        return value
    end
    return value
end

function lightWorks.canEmit(lightItem, channel)
    local value = lightWorks.getEmission(lightItem, channel)
    if type(value) == "number" then return value > 0 end
    if type(value) == "table" then
        local intensity = tonumber(value.intensity)
        return intensity == nil or intensity > 0
    end
    return value ~= nil and value ~= false
end

-- Generic spawn-time bulb weighting. Context keys are arbitrary strings such as
-- "default", "military", or "police". Third-party mods may register their own.
function lightWorks.registerSpawnBulbWeights(lightType, contextWeights)
    assert(type(lightType) == "string", "lightType is required")
    assert(type(contextWeights) == "table", "contextWeights must be a table")
    local stored = copyTable(contextWeights)
    lightWorks.SpawnBulbWeights[lightType] = stored
    return stored
end

function lightWorks.getSpawnBulbWeights(lightType, context)
    local def = lightWorks.SpawnBulbWeights[lightType]
    if not def then return nil end
    if context and def[context] then return def[context] end
    return def.default
end

local function random01()
    if ZombRand then return ZombRand(1000000) / 1000000.0 end
    return math.random()
end

function lightWorks.chooseWeightedBulb(weights)
    if type(weights) ~= "table" then return nil end
    local total = 0.0
    for _,weight in pairs(weights) do
        local n = tonumber(weight) or 0.0
        if n > 0 then total = total + n end
    end
    if total <= 0 then return nil end
    local roll = random01() * total
    local running = 0.0
    local types = {}
    for bulbType in pairs(weights) do types[#types + 1] = bulbType end
    table.sort(types)
    for _, bulbType in ipairs(types) do
        local weight = weights[bulbType]
        local n = math.max(0.0, tonumber(weight) or 0.0)
        if n > 0 then
            running = running + n
            if roll <= running then return bulbType end
        end
    end
    return nil
end

function lightWorks.applySpawnBulb(lightItem, context)
    if not lightWorks.isRegisteredLight(lightItem) then return false, nil end
    local lightType = fullType(lightItem)
    local weights = lightWorks.getSpawnBulbWeights(lightType, context)
    if not weights then return false, nil end
    local bulbType = lightWorks.chooseWeightedBulb(weights)
    if not bulbType or not lightWorks.isRegisteredBulb(bulbType) then return false, nil end

    local state = stateFor(lightItem)
    if not state then return false, nil end
    state.hasExplicitBulbState = true
    state.installedBulb = bulbType
    state.burnMinutes = 0.0
    state.burnedOut = false
    state.spawnBulbContext = context or "default"
    lightWorks.applyVisibleProfile(lightItem)
    return true, bulbType
end

local function applyDisplayName(lightItem)
    local light = lightWorks.getLightProfile(lightItem)
    if not light then return end

    local bulb = lightWorks.getInstalledBulb(lightItem)
    local state = stateFor(lightItem)
    if not state then return end
    local _, scriptItem = Access.call(lightItem, "getScriptItem")
    local _, scriptName = Access.call(scriptItem, "getDisplayName")
    local _, itemName = Access.call(lightItem, "getName")
    local baseName = scriptName or light.displayName or itemName or light.item

    local function translated(key,fallback)
        local get=rawget(_G,"getText")
        if type(get)~="function" or not key then return fallback end
        local ok,value=pcall(get,key)
        return ok and type(value)=="string" and value~="" and value~=key and value or fallback
    end
    local function bulbName(profile)
        local manager=rawget(_G,"ScriptManager")
        manager=manager and manager.instance or nil
        local _,script=Access.call(manager,"getItem",profile.item)
        local _,name=Access.call(script,"getDisplayName")
        return name or translated(profile.translationKey,profile.displayName)
    end

    if not bulb then
        Access.call(lightItem, "setName", baseName .. " (" .. translated("ContextMenu_lightWorks_NoBulb","No Bulb") .. ")")
    elseif bulb.item == light.defaultBulb then
        Access.call(lightItem, "setName", baseName)
    else
        Access.call(lightItem, "setName", baseName .. " (" .. bulbName(bulb) .. ")")
    end
end

local function applyBaseVisible(lightItem, state)
    if not state then return end
    if state.baseLightStrength ~= nil then
        Access.call(lightItem, "setLightStrength", state.baseLightStrength)
    end
    if state.baseLightDistance ~= nil then
        Access.call(lightItem, "setLightDistance", state.baseLightDistance)
    end
    if state.baseTorchCone ~= nil then
        Access.call(lightItem, "setTorchCone", state.baseTorchCone)
    end
    -- Torch dot is script-owned in this build; only the Lua renderer can override it.
end

local function cacheRenderedVisible(lightItem, state, visible)
    local ok, value = Access.call(lightItem,"getLightStrength")
    if ok then state.renderLightStrength = value end
    ok, value = Access.call(lightItem,"getLightDistance")
    if ok then state.renderLightDistance = value end
    ok, value = Access.call(lightItem,"isTorchCone")
    if ok then state.renderTorchCone = value end
    ok, value = Access.call(lightItem,"getTorchDot")
    if ok then state.renderTorchDot = value end
    local dot=visible and tonumber(visible.torchDot)
    if dot and dot==dot and dot>=-1 and dot<=1 then state.renderTorchDot=dot end
end

-- Mechanical light properties that PZ exposes directly on InventoryItem. The
-- client colored-torch bridge separately submits visible.color to LightingJNI,
-- because B42.20.3 does not read InventoryItem RGB when rendering a flashlight.
function lightWorks.applyVisibleProfile(lightItem)
    local light = lightWorks.getLightProfile(lightItem)
    if not light then return end

    local state = stateFor(lightItem)
    if not state then return false end

    -- 0.8.0-5 and earlier mistakenly used InventoryItem RGB for beam color,
    -- which persisted a tint on icons and dropped world models. Restore the
    -- originally captured item color once for existing saves; new lights never
    -- have these legacy fields and therefore require no item-color mutation.
    if not state.inventoryTintCleanupApplied then
        if state.baseColorRed~=nil then Access.call(lightItem,"setColorRed",state.baseColorRed) end
        if state.baseColorGreen~=nil then Access.call(lightItem,"setColorGreen",state.baseColorGreen) end
        if state.baseColorBlue~=nil then Access.call(lightItem,"setColorBlue",state.baseColorBlue) end
        state.baseColorRed,state.baseColorGreen,state.baseColorBlue=nil,nil,nil
        state.inventoryTintCleanupApplied=true
    end
    local bulb = lightWorks.getInstalledBulb(lightItem)

    if not bulb then
        Access.call(lightItem, "setLightStrength", 0.0)
        cacheRenderedVisible(lightItem,state)
        applyDisplayName(lightItem)
        return
    end

    -- Default/regular bulb restores the flashlight's captured stock settings.
    if bulb.item == light.defaultBulb then
        applyBaseVisible(lightItem, state)
        cacheRenderedVisible(lightItem,state)
        applyDisplayName(lightItem)
        return
    end

    local visible = bulb.visible or {}
    -- Start from stock so custom profiles only need to override what they care about.
    applyBaseVisible(lightItem, state)

    if visible.strength ~= nil then
        Access.call(lightItem, "setLightStrength", visible.strength)
    elseif visible.strengthMultiplier ~= nil and state.baseLightStrength ~= nil then
        Access.call(lightItem, "setLightStrength", state.baseLightStrength * visible.strengthMultiplier)
    end
    if visible.distance ~= nil then
        Access.call(lightItem, "setLightDistance", visible.distance)
    elseif visible.distanceMultiplier ~= nil and state.baseLightDistance ~= nil then
        Access.call(lightItem, "setLightDistance", math.max(0, math.floor(state.baseLightDistance * visible.distanceMultiplier + 0.5)))
    end
    if visible.torchCone ~= nil then
        Access.call(lightItem, "setTorchCone", visible.torchCone)
    end
    -- Presentation override stays in the existing Lua renderer cache, not native fields.
    cacheRenderedVisible(lightItem,state,visible)
    applyDisplayName(lightItem)
end

-- Installs a registered bulb into a compatible registered light.
-- Returns the old bulb type. A stock/unmodified light is treated as containing
-- its registered default bulb, so installing UV correctly returns Base.LightBulb.
local function refreshpowerWorks(lightItem)
    local power=rawget(_G,"powerWorks")
    if power and power.refreshConsumer then pcall(power.refreshConsumer,lightItem) end
end

-- Transaction snapshots belong to the light-state owner, not the UI action.
function lightWorks.captureServiceState(lightItem)
    local state=stateFor(lightItem)
    if not state then return nil end
    local ok,active=Access.call(lightItem,"isActivated")
    if not ok then ok,active=Access.call(lightItem,"getActivated") end
    return {state=copyTable(state),active=ok and active or false,hasActive=ok}
end

function lightWorks.restoreServiceState(lightItem,snapshot)
    if type(snapshot)~="table" or type(snapshot.state)~="table" then return false end
    local data=Access.modData(lightItem)
    if not data then return false end
    data[lightWorks.MODDATA_KEY]=copyTable(snapshot.state)
    lightWorks.applyVisibleProfile(lightItem)
    refreshpowerWorks(lightItem)
    if snapshot.hasActive then Access.call(lightItem,"setActivated",snapshot.active) end
    return true
end

function lightWorks.installBulb(lightItem, bulbItemOrType)
    if not lightWorks.isCompatible(lightItem, bulbItemOrType) then
        return false, nil, "incompatible"
    end

    local newType = fullType(bulbItemOrType)
    local oldType = lightWorks.getInstalledBulbType(lightItem)
    local state = stateFor(lightItem)
    if not state then return false, nil, "state_unavailable" end
    state.hasExplicitBulbState = true
    state.installedBulb = newType
    state.burnMinutes = 0.0
    state.burnedOut = false
    state.lastBurnedBulbType = nil

    lightWorks.applyVisibleProfile(lightItem)
    refreshpowerWorks(lightItem)
    return true, oldType, nil
end

-- Physically removes the installed bulb. The light becomes bulbless/off until
-- another bulb is installed. Returns the removed bulb type.
function lightWorks.removeBulb(lightItem)
    local light = lightWorks.getLightProfile(lightItem)
    if not light then return false, nil, "not_registered_light" end

    local oldType = lightWorks.getInstalledBulbType(lightItem)
    if not oldType then return false, nil, "no_bulb" end

    local state = stateFor(lightItem)
    if not state then return false, nil, "state_unavailable" end
    state.hasExplicitBulbState = true
    state.installedBulb = nil

    lightWorks.applyVisibleProfile(lightItem)
    refreshpowerWorks(lightItem)
    return true, oldType, nil
end


local function burnoutState(lightItem)
    local state = stateFor(lightItem)
    if not state then return nil end
    state.burnMinutes = tonumber(state.burnMinutes) or 0.0
    state.burnedOut = state.burnedOut == true
    return state
end

function lightWorks.getBulbBurnMinutes(lightItem)
    local state = burnoutState(lightItem)
    return state and state.burnMinutes or 0.0
end

function lightWorks.setBulbBurnMinutes(lightItem, minutes)
    local state = burnoutState(lightItem)
    if not state then return false end
    state.burnMinutes = math.max(0.0, tonumber(minutes) or 0.0)
    return true
end

function lightWorks.isBulbBurnedOut(lightItem)
    local state = burnoutState(lightItem)
    return state and state.burnedOut or false
end

function lightWorks.getBulbLifetimeMinutes(lightItem)
    local bulb = lightWorks.getInstalledBulb(lightItem)
    if not bulb then return 0.0 end

    local burnout = bulb.burnout or {}
    if burnout.disabled == true then return math.huge end
    if burnout.lifetimeMinutes ~= nil then
        return math.max(1.0, (tonumber(burnout.lifetimeMinutes) or lightWorks.Config.DefaultLifetimeMinutes)
            * math.max(0.01,tonumber(lightWorks.Config.BulbLifetimeMultiplier) or 1.0))
    end

    local mult = tonumber(burnout.lifetimeMultiplier) or 1.0
    return math.max(1.0, lightWorks.Config.DefaultLifetimeMinutes * mult
        * math.max(0.01,tonumber(lightWorks.Config.BulbLifetimeMultiplier) or 1.0))
end

function lightWorks.resetBulbBurnState(lightItem)
    local state = burnoutState(lightItem)
    if not state then return false end
    state.burnMinutes = 0.0
    state.burnedOut = false
    return true
end

-- Physically burns out the installed bulb. The light becomes bulbless/off.
-- Returns the configured broken-bulb item type for callers that want to give it
-- to a player/container.
function lightWorks.burnOutBulb(lightItem)
    local bulbType = lightWorks.getInstalledBulbType(lightItem)
    if not bulbType then return false, nil, "no_bulb" end

    local state = burnoutState(lightItem)
    state.burnedOut = true

    local ok, removedType = lightWorks.removeBulb(lightItem)
    if not ok then return false, nil, "remove_failed" end

    -- Preserve the fact that this was a burnout rather than a manual removal.
    state.burnedOut = true
    state.lastBurnedBulbType = removedType

    return true, lightWorks.Config.BurnedBulbItem, nil
end

-- Advances burn time only while a bulb is installed AND the light is activated.
-- Returns true, brokenItemType when burnout occurs.
function lightWorks.updateBulbBurnout(lightItem, elapsedGameMinutes)
    if not lightWorks.Config.EnableBurnout then return false, nil end
    if not lightWorks.isRegisteredLight(lightItem) then return false, nil end
    if not lightWorks.hasBulb(lightItem) then return false, nil end

    local active = false
    local okActive, value = Access.call(lightItem, "isActivated")
    if not okActive or value == nil then okActive, value = Access.call(lightItem, "getActivated") end
    active = okActive and value == true
    if not active then return false, nil end

    local state = burnoutState(lightItem)
    state.burnedOut = false
    state.burnMinutes = state.burnMinutes + math.max(0.0, tonumber(elapsedGameMinutes) or 0.0)

    local lifetime = lightWorks.getBulbLifetimeMinutes(lightItem)
    if state.burnMinutes >= lifetime then
        local ok, brokenType = lightWorks.burnOutBulb(lightItem)
        return ok, brokenType
    end
    return false, nil
end

-- Helper for mods that want to inspect arbitrary custom bulb data.
function lightWorks.describe(lightItem)
    return {
        lightType = fullType(lightItem),
        bulbType = lightWorks.getInstalledBulbType(lightItem),
        light = lightWorks.getLightProfile(lightItem),
        bulb = lightWorks.getInstalledBulb(lightItem),
    }
end

-- Stable alias so dependent mods can use either name.
lightWorks.API = lightWorks

-- Project Zomboid's require() returns the module's explicit return value.
-- Several shared consumers intentionally bind this result locally, so the
-- canonical API module must return its namespace instead of relying only on the
-- global compatibility symbol.
return lightWorks
