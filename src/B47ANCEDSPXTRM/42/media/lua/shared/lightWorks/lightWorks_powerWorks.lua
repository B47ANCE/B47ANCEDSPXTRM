require "lightWorks/lightWorks_API"

local lightWorks=lightWorks

local function resolve()
    -- Prefer the maintained dependency. No globals or saved power records are
    -- aliased; the old global is only an adapter for legacy consumer fixtures.
    local ok=pcall(require,"B47ANCEDPower/Definitions")
    local Power=ok and rawget(_G,"B47ANCEDPower") or nil
    if type(Power)~="table" then
        pcall(require,"powerWorks/Definitions")
        Power=rawget(_G,"powerWorks")
    end
    if type(Power)~="table" then return nil end
    for _,name in ipairs({"registerConsumer","getConsumerPowerState","refreshConsumer",
        "getConsumerEnergyRatePerHour","consumeEnergy"}) do
        if type(Power[name])~="function" then return nil end
    end
    return Power
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

lightWorks.registerPowerProfiles=registerProfiles
pcall(registerProfiles)
if Events and Events.OnGameStart then Events.OnGameStart.Add(registerProfiles) end
if Events and Events.OnServerStarted then Events.OnServerStarted.Add(registerProfiles) end

return lightWorks.powerWorks
