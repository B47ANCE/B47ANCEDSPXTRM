require "lightWorks/lightWorks_API"

local lightWorks = lightWorks

if not lightWorks.getLightCompatibilityProvider("lightWorks.Vanilla") then
    lightWorks.registerLightCompatibilityProvider({
        id="lightWorks.Vanilla",
        displayName="lightWorks verified vanilla lights",
        kind="core",
        targetModId="Base",
        verified=true,
    })
end

-- powerWorks consumes these profiles after lightWorks has completed verified
-- light registration. lightWorks owns light classification; powerWorks owns all
-- batteries, charge state, adapters, and power transactions.

local function bulb(item, name, r, g, b, visibilityMultiplier, strengthMultiplier, distanceMultiplier)
    lightWorks.registerBulb({
        item = item,
        displayName = name,
        tags = { VANILLA = true },
        visible = {
            color = { r = r, g = g, b = b },
            strengthMultiplier = strengthMultiplier or 1.0,
            distanceMultiplier = distanceMultiplier or 1.0,
        },
        detection = {
            visibilityMultiplier = visibilityMultiplier or 1.0,
        },
        emissions = {},
    })
end

-- Vanilla B42 bulbs.
bulb("Base.LightBulb",        "White Bulb",   1.00, 1.00, 1.00, 1.00, 1.00, 1.00)
bulb("Base.LightBulbRed",     "Red Bulb",     1.00, 0.00, 0.00, 0.70, 0.90, 0.90)
bulb("Base.LightBulbGreen",   "Green Bulb",   0.00, 1.00, 0.00, 0.90, 0.95, 0.95)
bulb("Base.LightBulbBlue",    "Blue Bulb",    0.00, 0.00, 1.00, 1.05, 1.00, 1.00)
bulb("Base.LightBulbCyan",    "Cyan Bulb",    0.00, 1.00, 1.00, 1.10, 1.00, 1.00)
bulb("Base.LightBulbMagenta", "Magenta Bulb", 1.00, 0.00, 1.00, 0.90, 0.95, 0.95)
bulb("Base.LightBulbOrange",  "Orange Bulb",  1.00, 0.50, 0.00, 0.90, 0.95, 0.95)
bulb("Base.LightBulbPink",    "Pink Bulb",    1.00, 0.40, 0.65, 0.95, 0.98, 0.98)
bulb("Base.LightBulbPurple",  "Purple Bulb",  0.50, 0.00, 1.00, 0.85, 0.92, 0.92)
bulb("Base.LightBulbYellow",  "Yellow Bulb",  1.00, 1.00, 0.00, 1.05, 1.00, 1.00)

-- Vanilla B42 items using the Flashlight tag.
local serviceTools = {
    "Base.Screwdriver",
    "Base.Pliers",
    "Base.ViseGrips",
    "Base.Multitool",
}

-- Tool requirements are per-light rather than universal. Lights whose bulb
-- compartments are plausibly hand-accessible stay tool-free; sealed/rugged
-- housings and weapon-mounted lights require a maintenance tool.
local vanillaLights = {
    { item="Base.HandTorch",                 name="Flashlight",                       tools=false,        removeBulbTime=35, installBulbTime=45,  power={sizes={"AA","AA_PACK","LEGACY"},drainMultiplier=1.0}, emitter={class="handheld",range=12,strength=0.72,cone=true,width=0.72,nodes=4,falloff=0.72}, attachment={belt=true,type="lightWorks_BeltDownLight",geometry="down",staticModel="lightWorks_HandTorchBelt"} },
    { item="Base.Torch",                     name="Flashlight - Heavy Duty",          tools=serviceTools, removeBulbTime=80, installBulbTime=100, power={sizes={"D","D_PACK","LEGACY"},drainMultiplier=0.75}, emitter={class="heavy",range=20,strength=1.0,cone=true,width=0.9,nodes=5,falloff=0.82} },
    { item="Base.FlashLight_AngleHead",      name="Flashlight - Angle Headed",        tools=serviceTools, removeBulbTime=85, installBulbTime=105, power={sizes={"D","D_PACK","LEGACY"},drainMultiplier=1.0}, emitter={class="angle",range=14,strength=0.78,cone=true,width=0.8,nodes=4,falloff=0.76}, attachment={belt=true,webbing=true,type="lightWorks_AngleLight",geometry="outward",staticModel="lightWorks_AngleHeadBelt"} },
    { item="Base.FlashLight_AngleHead_Army", name="Flashlight - Angle Headed (Army)", tools=serviceTools, removeBulbTime=95, installBulbTime=115, power={sizes={"D","D_PACK","LEGACY"},drainMultiplier=1.0}, emitter={class="angle_military",range=16,strength=0.86,cone=true,width=0.72,nodes=5,falloff=0.8}, attachment={belt=true,webbing=true,type="lightWorks_AngleLight",geometry="outward",staticModel="lightWorks_AngleHeadArmyBelt"} },
    { item="Base.PenLight",                  name="Penlight",                         tools=serviceTools, removeBulbTime=80, installBulbTime=100, power={sizes={"AAA","LEGACY"},drainMultiplier=0.65}, emitter={class="penlight",range=8,strength=0.46,cone=true,width=0.42,nodes=3,falloff=0.65}, attachment={belt=true,type="lightWorks_BeltDownLight",geometry="down",staticModel="lightWorks_PenLightBelt"} },
    { item="Base.Lantern_CraftedElectric",   name="Improvised Electric Lantern",      tools=false,        removeBulbTime=40, installBulbTime=50, power={sizes={"AA","AA_PACK","LEGACY"},drainMultiplier=1.0}, emitter={class="standing_area",range=7,strength=0.72,cone=false,width=1.0,nodes=1,falloff=0.62} },
    { item="Base.Flashlight_Crafted",        name="Flashlight - Improvised",          tools=false,        removeBulbTime=40, installBulbTime=50, power={sizes={"AA","AA_PACK","LEGACY"},drainMultiplier=1.0}, emitter={class="improvised",range=9,strength=0.54,cone=true,width=1.0,nodes=3,falloff=0.58} },
    { item="Base.GunLight",                  name="Gun Light",                        tools=serviceTools, removeBulbTime=100, installBulbTime=120, power={sizes={"AA","AA_PACK","LEGACY"},drainMultiplier=1.0}, emitter={class="weapon",range=11,strength=0.68,cone=true,width=0.38,nodes=4,falloff=0.76} },
}

-- Physical reference metadata is deliberately separate from live renderer
-- values. It documents the 1993 device/emitter/optic identity and gives future
-- calibration/migration code one canonical source without silently changing
-- established beam visuals or one-item battery state.
local physicalProfiles={
    ["Base.HandTorch"]={
        physical={analogue="Mini Maglite 2AA class",reflector="compact-adjustable",focusModes={"flood","spot"},filterSocket=false},
        emitter={technology="xenon-incandescent",nominalLumens=14,nominalCandela=2305,ratedThrowMeters=96,usefulRangeTargetMeters=22,colorTemperatureK=3000,lowVoltageBehavior="incandescent-dim-warm"},
        power={nominalCellCount=2,nominalVoltage=3.0,runtimeTargetHours=5.25},
    },
    ["Base.Torch"]={
        physical={analogue="full-size 2D Maglite class",reflector="large-adjustable",focusModes={"flood","spot"},filterSocket=false},
        emitter={technology="xenon-incandescent",nominalLumens=27,nominalCandela=10627,ratedThrowMeters=206,usefulRangeTargetMeters=35,colorTemperatureK=3000,lowVoltageBehavior="incandescent-dim-warm"},
        power={nominalCellCount=2,nominalVoltage=3.0,runtimeTargetHours=8.5},
    },
    ["Base.FlashLight_AngleHead"]={
        physical={analogue="industrial right-angle flashlight",reflector="utility",focusModes={"fixed"},filterSocket=false},
        emitter={technology="incandescent",nominalLumensClass="low-tens",usefulRangeTargetMeters=18,colorTemperatureK=2900,lowVoltageBehavior="incandescent-dim-warm"},
        power={nominalCellCount=2,nominalVoltage=3.0,runtimeTargetHours=9.0},
    },
    ["Base.FlashLight_AngleHead_Army"]={
        physical={analogue="Fulton MX-991/U class",reflector="military-utility",focusModes={"fixed"},filterSocket=true,supportedFilters={"clear","red","blue","diffuser"},spareLampStorage=true},
        emitter={technology="PR6-incandescent",nominalLumensClass="low-tens",usefulRangeTargetMeters=20,colorTemperatureK=2900,lowVoltageBehavior="incandescent-dim-warm"},
        power={nominalCellCount=2,nominalVoltage=3.0,runtimeTargetHours=9.0},
    },
    ["Base.PenLight"]={
        physical={analogue="Maglite Solitaire class",reflector="inspection",focusModes={"fixed"},filterSocket=false},
        emitter={technology="incandescent",nominalLumens=2,nominalCandela=97,ratedThrowMeters=20,usefulRangeTargetMeters=8,colorTemperatureK=2900,lowVoltageBehavior="incandescent-dim-warm"},
        power={nominalCellCount=1,nominalVoltage=1.5,runtimeTargetHours=3.75},
    },
    ["Base.Lantern_CraftedElectric"]={physical={analogue="improvised area lantern",reflector="radial"},emitter={technology="incandescent",usefulRangeTargetMeters=10,colorTemperatureK=2900},power={nominalCellCount=2}},
    ["Base.Flashlight_Crafted"]={physical={analogue="improvised hand light",reflector="crude"},emitter={technology="incandescent",usefulRangeTargetMeters=9,colorTemperatureK=2800},power={nominalCellCount=2}},
    ["Base.GunLight"]={physical={analogue="early-1990s tactical incandescent (provisional)",reflector="compact-tactical",researchStatus="provisional"},emitter={technology="incandescent",usefulRangeTargetMeters=15,colorTemperatureK=3000},power={nominalCellCount=1,researchStatus="provisional"}},
}

for _,def in ipairs(vanillaLights) do
    local reference=physicalProfiles[def.item]
    if reference then
        def.physical=reference.physical
        for key,value in pairs(reference.emitter or {}) do def.emitter[key]=value end
        for key,value in pairs(reference.power or {}) do def.power[key]=value end
    end
end

for _, def in ipairs(vanillaLights) do
    lightWorks.registerVerifiedLight("lightWorks.Vanilla", {
        item = def.item,
        displayName = def.name,
        defaultBulb = "Base.LightBulb",
        tools = def.tools,
        removeBulbTime = def.removeBulbTime,
        installBulbTime = def.installBulbTime,
        attachment = def.attachment,
        emitter = def.emitter,
        power = def.power or {sizes={"AA","LEGACY"},drainMultiplier=1.0},
        physical = def.physical,
    })
end


-- Tactical spawn profiles.
-- Gun Lights: 12% red wherever a vanilla Gun Light is generated.
lightWorks.registerSpawnBulbWeights("Base.GunLight", {
    default = {
        ["Base.LightBulb"] = 0.88,
        ["Base.LightBulbRed"] = 0.12,
    },
})

-- Ordinary Angle-Headed Flashlights only get a red-bulb chance when generated
-- from explicitly military or police loot contexts.
lightWorks.registerSpawnBulbWeights("Base.FlashLight_AngleHead", {
    default = {
        ["Base.LightBulb"] = 1.00,
    },
    military = {
        ["Base.LightBulb"] = 0.90,
        ["Base.LightBulbRed"] = 0.10,
    },
    police = {
        ["Base.LightBulb"] = 0.90,
        ["Base.LightBulbRed"] = 0.10,
    },
})

-- Army Angle-Headed Flashlights are normally configured as tactical red lights.
lightWorks.registerSpawnBulbWeights("Base.FlashLight_AngleHead_Army", {
    default = {
        ["Base.LightBulbRed"] = 0.80,
        ["Base.LightBulb"] = 0.20,
    },
})
