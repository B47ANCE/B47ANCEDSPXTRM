require "lightWorks/lightWorks_API"

local lightWorks=lightWorks

local function resolve()
    local ok = pcall(require, "powerWorks/Definitions")
    if not ok then return nil end
    return rawget(_G,"powerWorks")
end

local function registerProfiles()
    local Power=resolve()
    if not Power or not Power.registerConsumer then return false end
    for itemType,light in pairs(lightWorks.Lights) do
        if light.power then
            Power.registerConsumer({
                item=itemType,
                provider="lightWorks",
                sizes=light.power.sizes,
                referenceCapacity=light.power.referenceCapacity,
                drainMultiplier=light.power.drainMultiplier,
                nominalCellCount=light.power.nominalCellCount,
                nominalVoltage=light.power.nominalVoltage,
                runtimeTargetHours=light.power.runtimeTargetHours,
                accessToolRequired=light.tools~=false,
                loadResolver=function(item)
                    return lightWorks.getInstalledBulbType(item)
                end,
                consumptionResolver=function(item)
                    return lightWorks.Patterns and lightWorks.Patterns.getDutyCycle(item) or 1
                end,
            })
        end
    end
    lightWorks.powerWorks=Power
    return true
end

pcall(registerProfiles)
if Events and Events.OnGameStart then Events.OnGameStart.Add(registerProfiles) end
if Events and Events.OnServerStarted then Events.OnServerStarted.Add(registerProfiles) end

return lightWorks.powerWorks
