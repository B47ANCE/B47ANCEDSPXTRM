-- Explicit sandbox schema; bounds mirror media/sandbox-options.txt.
local Sandbox={}
Sandbox.schema={
    EnableBurnout={kind="boolean",default=true},
    BulbLifetimeMultiplier={kind="double",default=1.0,min=0.05,max=20.0},
    ServiceTimeMultiplier={kind="double",default=1.0,min=0.05,max=10.0},
    RequireServiceTools={kind="boolean",default=true},
    EnableAutomaticDiscovery={kind="boolean",default=true},
    EnableColoredLightRenderer={kind="boolean",default=true},
    EnableAttachmentGeometry={kind="boolean",default=true},
    EnableSpawnBulbConfiguration={kind="boolean",default=true},
    EnableSunburn={kind="boolean",default=true},
    SunburnDoseMultiplier={kind="double",default=1.0,min=0.0,max=10.0},
    SunburnFirstDegreeDoseHours={kind="double",default=0.75,min=0.1,max=24.0},
    SunburnMaximumDoseHours={kind="double",default=4.0,min=0.2,max=72.0},
    SunburnRecoveryDoseHoursPerHour={kind="double",default=0.10,min=0.0,max=4.0},
    EnableLowBatteryFlicker={kind="boolean",default=true},
    LowBatteryFlickerThreshold={kind="double",default=0.10,min=0.01,max=0.50},
    LowBatteryFlickerPeriodMs={kind="integer",default=4000,min=500,max=15000},
    LowBatteryFlickerMinimumOffFraction={kind="double",default=0.08,min=0.0,max=0.95},
    LowBatteryFlickerMaximumOffFraction={kind="double",default=0.55,min=0.0,max=0.95},
    EnableLightPatterns={kind="boolean",default=true},
    EnableWorldEmitters={kind="boolean",default=true},
    EnableClothingSunProtection={kind="boolean",default=true},
    SunburnClothingProtection={kind="double",default=0.90,min=0.0,max=1.0},
    EnableLasers={kind="boolean",default=true},
    LaserRangeMultiplier={kind="double",default=1.0,min=0.1,max=2.0},
    EnableLaserBeams={kind="boolean",default=false},
    EnableWaterUVIntegration={kind="boolean",default=false},
    WaterUVMinimumIntensity={kind="double",default=0.5,min=0.001,max=100.0},
    WaterUVMaximumTurbidity={kind="double",default=0.25,min=0.0,max=1.0},
    WaterUVBiologicalReduction={kind="double",default=0.90,min=0.0,max=0.99},
}
function Sandbox.read(values)
    values=type(values)=="table" and values or {}
    local result={}
    for key,rule in pairs(Sandbox.schema) do
        local v=values[key]
        if rule.kind=="boolean" then
            if type(v)~="boolean" then v=rule.default end
        elseif type(v)~="number" or v~=v or math.abs(v)==math.huge then v=rule.default
        else
            v=math.max(rule.min,math.min(rule.max,v))
            if rule.kind=="integer" then v=math.floor(v) end
        end
        result[key]=v
    end
    result.SunburnMaximumDoseHours=math.max(result.SunburnFirstDegreeDoseHours+.01,result.SunburnMaximumDoseHours)
    result.LowBatteryFlickerMaximumOffFraction=math.max(result.LowBatteryFlickerMinimumOffFraction,result.LowBatteryFlickerMaximumOffFraction)
    return result
end
return Sandbox
