-- Development-only in-game harness; confirmed debug mode is required.
if type(isDebugEnabled)~="function" or isDebugEnabled()~=true then return {} end

require "lightWorks/lightWorks_API"
require "lightWorks/lightWorks_Vanilla"
require "lightWorks/lightWorks_UV"
require "lightWorks/lightWorks_ChangeBulbAction"
require "TimedActions/ISTimedActionQueue"
require "ISUI/ISTextBox"

local lightWorks = lightWorks
lightWorks.TestHarness = lightWorks.TestHarness or {}
local Harness = lightWorks.TestHarness
Harness.tourCompletionListeners = Harness.tourCompletionListeners or {}
local KIT_MARKER = "lightWorks.TestKitVersion"
local tour = { active=false, index=0, results={} }
local function spOnly()
    return not(type(isClient)=="function" and isClient()==true) and not(type(isServer)=="function" and isServer()==true)
end

local TOUR_LIGHTS = {
    {type="Base.HandTorch",name="standard flashlight",expect="A medium white/purple forward beam appears. Its inventory icon and ground model must not change color."},
    {type="Base.Torch",name="heavy-duty flashlight",expect="The forward beam is visibly longer and stronger than the standard flashlight. This light must not attach to a belt."},
    {type="Base.FlashLight_AngleHead",name="angle-headed flashlight",expect="The beam points outward rather than straight down. When attached, its direction must match the side used."},
    {type="Base.FlashLight_AngleHead_Army",name="military angle-headed flashlight",expect="A colored outward beam appears cleanly, with no white-beam or inventory-icon tint."},
    {type="Base.PenLight",name="penlight",expect="A short, narrow beam appears and is clearly smaller than the standard flashlight beam."},
    {type="Base.Lantern_CraftedElectric",name="electric lantern",expect="A radial halo surrounds the character instead of a forward cone."},
    {type="Base.Flashlight_Crafted",name="crafted flashlight",expect="A stable forward beam appears with no flicker at full charge and no missing texture or model."},
}

local CORE_KIT = {
    {"Base.HandTorch", 1}, {"Base.Torch", 1}, {"Base.FlashLight_AngleHead", 1},
    {"Base.FlashLight_AngleHead_Army", 1}, {"Base.PenLight", 1}, {"Base.GunLight", 1},
    {"Base.Battery", 6}, {"Base.Screwdriver", 1}, {"Base.Pliers", 1},
    {"B47ANCEDPower.BatteryAAA", 2}, {"B47ANCEDPower.BatteryAA", 4},
    {"B47ANCEDPower.BatteryD", 2}, {"B47ANCEDPower.BatteryAAImprovised", 1},
    {"Base.ViseGrips", 1}, {"Base.Multitool", 1}, {"Base.LightBulb", 4},
    {"Base.LightBulbRed", 3}, {"Base.LightBulbGreen", 2}, {"Base.LightBulbBlue", 2},
    {"Base.LightBulbCyan", 2}, {"Base.LightBulbMagenta", 2}, {"Base.LightBulbOrange", 2},
    {"Base.LightBulbPink", 2}, {"Base.LightBulbPurple", 2}, {"Base.LightBulbYellow", 2},
}

local function player0()
    return (getSpecificPlayer and getSpecificPlayer(0)) or (getPlayer and getPlayer()) or nil
end

local function add(inventory, fullType)
    local ok, item = pcall(function() return inventory:AddItem(fullType) end)
    return ok and item or nil
end

local function ensureItem(player, fullType)
    local item = lightWorks.findFirstInventoryItem(player, fullType)
    if item then return item end
    local inventory = player and player:getInventory() or nil
    return inventory and add(inventory, fullType) or nil
end

local function log(message)
    print("[lightWorks][Test] " .. tostring(message))
end

function Harness.giveKit(force)
    if not spOnly() then return false,"SP-only fixture helper; use validated gameplay actions in MP" end
    local player = player0()
    if not player then return false, "player unavailable" end
    local inventory = player:getInventory()
    if not inventory then return false, "inventory unavailable" end
    local md = player:getModData()
    if not force and md[KIT_MARKER] == lightWorks.VERSION then
        log("Kit already granted; use LWTestKit(true) to force another")
        return false, "already granted"
    end
    local granted, missing = 0, {}
    for _, entry in ipairs(CORE_KIT) do
        for _ = 1, entry[2] do
            if add(inventory, entry[1]) then granted = granted + 1 else missing[#missing + 1] = entry[1] end
        end
    end
    for bulbType in pairs(lightWorks.Bulbs) do
        if not lightWorks.findFirstInventoryItem(player, bulbType) then
            if add(inventory, bulbType) then granted = granted + 1 else missing[#missing + 1] = bulbType end
        end
    end
    md[KIT_MARKER] = lightWorks.VERSION
    log(string.format("Kit ready: granted=%d unavailable=%d", granted, #missing))
    if #missing > 0 then log("Unavailable: " .. table.concat(missing, ", ")) end
    return true, {granted=granted, missing=missing}
end

local function resolveLight(player, lightType)
    lightType = lightType or "Base.HandTorch"
    local light = lightWorks.findFirstInventoryItem(player, lightType)
    if not light then light = ensureItem(player, lightType) end
    if not light then return nil, "could not create " .. tostring(lightType) end
    if not lightWorks.isRegisteredLight(light) then return nil, tostring(lightType) .. " is not registered" end
    return light
end

function Harness.queueChange(lightType, bulbType)
    if not spOnly() then return false,"SP-only fixture helper; use validated gameplay actions in MP" end
    local player = player0()
    if not player then return false, "player unavailable" end
    Harness.giveKit(false)
    local light, err = resolveLight(player, lightType)
    if not light then log("FAIL: " .. err); return false, err end
    if not bulbType or not lightWorks.isRegisteredBulb(bulbType) then
        err = "unregistered bulb " .. tostring(bulbType)
        log("FAIL: " .. err); return false, err
    end
    if not lightWorks.isCompatible(light, bulbType) then
        err = tostring(bulbType) .. " is incompatible with " .. tostring(lightType)
        log("FAIL: " .. err); return false, err
    end
    if not ensureItem(player, bulbType) then
        err = "could not create replacement bulb " .. tostring(bulbType)
        log("FAIL: " .. err); return false, err
    end
    local canService, _, reason = lightWorks.canServiceLight(player, light)
    if not canService then log("FAIL: cannot service light: " .. tostring(reason)); return false, reason end
    ISTimedActionQueue.add(lightWorks.ChangeBulbAction:new(player, light, "install", bulbType))
    log("Queued real timed change: " .. tostring(lightType) .. " -> " .. tostring(bulbType))
    return true, light
end

function Harness.queueRemove(lightType)
    if not spOnly() then return false,"SP-only fixture helper; use validated gameplay actions in MP" end
    local player = player0()
    if not player then return false, "player unavailable" end
    Harness.giveKit(false)
    local light, err = resolveLight(player, lightType)
    if not light then log("FAIL: " .. err); return false, err end
    if not lightWorks.hasBulb(light) then log("FAIL: light has no bulb"); return false, "no bulb" end
    ISTimedActionQueue.add(lightWorks.ChangeBulbAction:new(player, light, "remove", nil))
    log("Queued real timed removal: " .. tostring(lightType))
    return true, light
end

function Harness.queueCycle(lightType)
    if not spOnly() then return false,"SP-only fixture helper; use validated gameplay actions in MP" end
    local player = player0()
    if not player then return false, "player unavailable" end
    Harness.giveKit(false)
    local light, err = resolveLight(player, lightType)
    if not light then log("FAIL: " .. err); return false, err end
    local preferred = {
        "Base.LightBulbRed", "Base.LightBulbGreen", "Base.LightBulbBlue",
        "Base.LightBulbPurple", "ProjectNightfall.LightBulbUV",
        "ProjectNightfall.LightBulbUVHighOutput", "Base.LightBulb",
    }
    local queued = 0
    for _, bulbType in ipairs(preferred) do
        if lightWorks.isRegisteredBulb(bulbType) and lightWorks.isCompatible(light, bulbType) then
            ensureItem(player, bulbType)
            ISTimedActionQueue.add(lightWorks.ChangeBulbAction:new(player, light, "install", bulbType))
            queued = queued + 1
        end
    end
    log(string.format("Queued %d real bulb-change actions for %s", queued, tostring(lightType or "Base.HandTorch")))
    return queued > 0, light
end

function Harness.runChecks()
    if not spOnly() then return false,"SP-only fixture helper; use validated gameplay actions in MP" end
    local player = player0()
    if not player then return false, "player unavailable" end
    Harness.giveKit(false)
    local passed, failed = 0, 0
    local function check(name, condition)
        if condition then passed = passed + 1; log("PASS " .. name)
        else failed = failed + 1; log("FAIL " .. name) end
    end
    local light = add(player:getInventory(), "Base.HandTorch")
    check("created sacrificial registered light", light and lightWorks.isRegisteredLight(light))
    if light then
        local serviceable = lightWorks.canServiceLight(player, light)
        check("required-tool/service path", serviceable == true)
        check("default bulb present", lightWorks.hasBulb(light) == true)
        local red = lightWorks.isRegisteredBulb("Base.LightBulbRed") and "Base.LightBulbRed" or nil
        if red then
            local ok, old = lightWorks.installBulb(light, red)
            check("install API", ok and old ~= nil and lightWorks.getInstalledBulbType(light) == red)
            check("red visibility semantic", lightWorks.getZombieVisibilityMultiplier(light) < 1.0)
        end
        local okRemove, removed = lightWorks.removeBulb(light)
        check("remove API", okRemove and removed ~= nil and not lightWorks.hasBulb(light))
        local okRestore = lightWorks.installBulb(light, "Base.LightBulb")
        check("restore default bulb", okRestore and lightWorks.getInstalledBulbType(light) == "Base.LightBulb")
        check("unknown item fails closed", lightWorks.canServiceLight(player, "Base.Apple") == false)
        local uv = lightWorks.isRegisteredBulb("ProjectNightfall.LightBulbUV") and "ProjectNightfall.LightBulbUV" or nil
        if uv then
            local okUV = lightWorks.installBulb(light, uv)
            check("Nightfall UV install", okUV and lightWorks.canEmit(light, "UV"))
        else
            log("SKIP Nightfall UV checks (Nightfall bulb not registered)")
        end

        local Power = rawget(_G, "B47ANCEDPower") or lightWorks.powerWorks
        if Power and type(Power.installBattery) == "function" then
            check("required powerWorks integration available", true)
            pcall(function() light:setActivated(false) end)
            pcall(function() light:setUsedDelta(0) end)
            local profile = Power.getConsumerProfile(light)
            local firstSize = profile and profile.sizes and profile.sizes[1] or "AA"
            local batteryType = firstSize=="D" and "B47ANCEDPower.BatteryD" or firstSize=="AAA"
                and "B47ANCEDPower.BatteryAAA" or "B47ANCEDPower.BatteryAA"
            local battery = add(player:getInventory(), batteryType)
            local required = Power.getRequiredCellCount and Power.getRequiredCellCount(light, battery) or 1
            local cells = battery and {battery} or {}
            for _=2,(tonumber(required) or 1) do cells[#cells+1]=add(player:getInventory(), batteryType) end
            check("created complete matching AA cell set", #cells==(tonumber(required) or 1)
                and cells[1] and Power.accepts(light, cells[1]))
            if #cells==(tonumber(required) or 1) and cells[1] then
                local installed = #cells>1 and Power.installBatterySet(player, light, cells)
                    or Power.installBattery(player, light, cells[1])
                check("powerWorks install", installed and Power.getInstalledBatteryType(light) == batteryType)
                local extracted, returned = Power.extractBattery(player, light)
                check("powerWorks extraction", extracted and returned and Power.getInstalledBatteryType(light) == nil)
            end
        else
            check("required powerWorks integration available", false)
        end
        check("UV exposure API available", lightWorks.UV and type(lightWorks.UV.getExposure) == "function"
            and type(lightWorks.UV.getSunlightExposure) == "function")
    end
    log(string.format("SUMMARY PASS=%d FAIL=%d; visual checks remain manual", passed, failed))
    return failed == 0, {passed=passed, failed=failed}
end

local function setActiveLight(player, light, active)
    if player and light and active then
        pcall(function() player:setSecondaryHandItem(light) end)
        pcall(function() light:setUsedDelta(1.0) end)
    end
    if light then
        pcall(function() light:setActivated(active == true) end)
    end
end

local function tourSummary()
    local passed, issues = 0, 0
    log("GUIDED TOUR RESULTS")
    for _, result in ipairs(tour.results) do
        local report = tostring(result.report or "")
        local ok = string.upper(report) == "PASS"
        if ok then passed = passed + 1 else issues = issues + 1 end
        log(string.format("%s %s: %s", ok and "PASS" or "ISSUE", result.lightName or result.lightType, report))
    end
    log(string.format("GUIDED TOUR SUMMARY PASS=%d ISSUES=%d", passed, issues))
    log("POST-SUITE: save/reload one UV light; right-click one nested and one attached light; test Gun Light on a weapon; then close the game and review console.txt")
    tour.active = false
    local listeners=Harness.tourCompletionListeners
    Harness.tourCompletionListeners={}
    for _,listener in ipairs(listeners) do
        local ok,err=pcall(listener,tour.results)
        if not ok then log("Tour-completion listener failed safely: "..tostring(err)) end
    end
end

function Harness.whenTourCompletes(callback)
    if type(callback)~="function" then return false,"callback required" end
    Harness.tourCompletionListeners[#Harness.tourCompletionListeners+1]=callback
    return true
end

local function advanceTour()
    if not tour.active then return end
    tour.index = tour.index + 1
    local checkpoint = TOUR_LIGHTS[tour.index]
    if not checkpoint then tourSummary(); return end
    local lightType = checkpoint.type
    local player = player0()
    local light, err = resolveLight(player, lightType)
    if not light then
        tour.results[#tour.results + 1] = {lightType=lightType, report="SETUP FAILED: " .. tostring(err)}
        advanceTour()
        return
    end
    local bulbType = lightWorks.isRegisteredBulb("ProjectNightfall.LightBulbUV")
        and "ProjectNightfall.LightBulbUV" or "Base.LightBulbPurple"
    ensureItem(player, bulbType)
    tour.currentLight = light
    tour.currentType = lightType
    tour.currentName = checkpoint.name
    tour.currentExpectation = checkpoint.expect
    tour.targetBulb = bulbType
    tour.waitingForAction = true
    ISTimedActionQueue.add(lightWorks.ChangeBulbAction:new(player, light, "install", bulbType))
    log(string.format("TOUR %d/%d: preparing the %s. Expected: %s", tour.index, #TOUR_LIGHTS, checkpoint.name, checkpoint.expect))
end

function Harness:onTourReport(button)
    if not tour.active then return end
    local report = "NO REPORT"
    if button and button.parent and button.parent.entry then
        local ok, text = pcall(function() return button.parent.entry:getText() end)
        if ok and text and text ~= "" then report = text end
    end
    tour.results[#tour.results + 1] = {lightType=tour.currentType, lightName=tour.currentName,
        expectation=tour.currentExpectation, report=report}
    setActiveLight(player0(), tour.currentLight, false)
    tour.currentLight, tour.currentType, tour.currentName, tour.currentExpectation, tour.targetBulb = nil, nil, nil, nil, nil
    advanceTour()
end

local function showTourPrompt()
    local core = getCore and getCore() or nil
    local width, height = 520, 190
    local screenW = core and core:getScreenWidth() or 1280
    local screenH = core and core:getScreenHeight() or 720
    local message = string.format(
        "LIGHTWORKS TOUR %d/%d — %s\n\nExpected: %s\n\nTurn and move with the light. Enter PASS only if the expected result is visible; otherwise describe what happened.",
        tour.index, #TOUR_LIGHTS, tostring(tour.currentName or tour.currentType), tostring(tour.currentExpectation or "Inspect the light."))
    local box = ISTextBox:new(
        math.floor((screenW-width)/2), math.floor((screenH-height)/2),
        width, height, message, "PASS", Harness, Harness.onTourReport, 0
    )
    box:initialise()
    box:addToUIManager()
end

local function updateTour()
    if not tour.active or not tour.waitingForAction or not tour.currentLight then return end
    if lightWorks.getInstalledBulbType(tour.currentLight) ~= tour.targetBulb then return end
    tour.waitingForAction = false
    setActiveLight(player0(), tour.currentLight, true)
    showTourPrompt()
end

function Harness.startTour()
    if not spOnly() then return false,"SP-only fixture helper; use validated gameplay actions in MP" end
    if tour.active then log("Guided tour is already running"); return false, "already running" end
    local player = player0()
    if not player then return false, "player unavailable" end
    Harness.giveKit(false)
    tour.active, tour.index, tour.results = true, 0, {}
    log("Starting the guided playtester tour. Move and turn at each prompt; enter PASS only when its plain-language expectation is visible.")
    advanceTour()
    return true
end

function Harness.startReleaseSuite()
    if not spOnly() then return false,"SP-only fixture helper; use validated gameplay actions in MP" end
    if tour.active then log("Release suite cannot start while the guided tour is active"); return false, "already running" end
    log("RELEASE SUITE: automated API/state checks followed by the guided visual tour")
    local checksOK, results = Harness.runChecks()
    if not checksOK then
        log(string.format("RELEASE SUITE: automated failures=%d; continuing so visual issues can also be recorded", results and results.failed or -1))
    end
    local started, reason = Harness.startTour()
    return started, {checks=results, tourStarted=started, reason=reason}
end

function LWTestKit(force) return Harness.giveKit(force == true) end
function LWTestChangeBulb(lightType, bulbType) return Harness.queueChange(lightType, bulbType) end
function LWTestRemoveBulb(lightType) return Harness.queueRemove(lightType) end
function LWTestCycleBulbs(lightType) return Harness.queueCycle(lightType) end
function LWRunIntegrationTests() return Harness.runChecks() end
function LWStartDebugTour() return Harness.startTour() end
function LWStartReleaseSuite() return Harness.startReleaseSuite() end
function LWOnTestTourComplete(callback) return Harness.whenTourCompletes(callback) end

Events.OnTick.Add(updateTour)
log("Ready: LWStartReleaseSuite(), LWStartDebugTour(), LWTestKit(), LWRunIntegrationTests(), LWTestCycleBulbs(), LWTestChangeBulb(lightType, bulbType), LWTestRemoveBulb(lightType)")

return Harness
