require "lightWorks/lightWorks_API"
require "lightWorks/lightWorks_Vanilla"

local lightWorks = lightWorks
local Access = require "lightWorks/lightWorks_ItemAccess"
local lastWorldAgeHours = nil
local accumulatorMinutes = 0.0

local function giveBrokenBulb(player, fullType)
    if not player or not fullType then return end
    Access.addItem(player, fullType)
end

local function elapsedGameMinutes()
    local gt = getGameTime and getGameTime() or nil
    if not gt then return 0.0 end
    local now = gt:getWorldAgeHours()
    if not lastWorldAgeHours then
        lastWorldAgeHours = now
        return 0.0
    end
    local minutes = math.max(0.0, (now-lastWorldAgeHours)*60.0)
    lastWorldAgeHours = now
    return math.min(minutes, 10.0)
end

local function onTick()
    local dt = elapsedGameMinutes()
    if dt <= 0 then return end

    accumulatorMinutes = accumulatorMinutes + dt
    if accumulatorMinutes < lightWorks.Config.BurnoutCheckEveryGameMinutes then return end

    local elapsed = accumulatorMinutes
    accumulatorMinutes = 0.0

    for playerNum = 0, 3 do
        local player = getSpecificPlayer and getSpecificPlayer(playerNum) or nil
        if player then
            for _,light in ipairs(lightWorks.collectPlayerLights(player)) do
                local burned, brokenType = lightWorks.updateBulbBurnout(light, elapsed)
                if burned then
                    giveBrokenBulb(player, brokenType)
                    print("[lightWorks] Bulb burned out in " .. tostring(Access.fullType(light)))
                end
            end
        end
    end
end

Events.OnTick.Add(onTick)
