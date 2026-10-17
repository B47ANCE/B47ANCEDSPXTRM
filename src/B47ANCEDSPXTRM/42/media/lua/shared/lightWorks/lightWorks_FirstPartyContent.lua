local API=require "lightWorks/lightWorks_API"
local Content={}
local definitions={
    {item="UVAInspectionLamp",bulb="UVABulb",name="UVA Inspection Lamp",range=10,strength=.5,uv=1.0,band="uva",multiplier=1.2},
    {item="UVCServiceLamp",bulb="UVCBulb",name="UVC Service Lamp",range=6,strength=.25,uv=2.0,band="uvc",multiplier=2.0},
    {item="GrowLamp",bulb="GrowBulb",name="Portable Grow Lamp",range=8,strength=.85,multiplier=1.5},
}
if not API.getLightCompatibilityProvider("lightWorks.FirstParty") then
    API.registerLightCompatibilityProvider{id="lightWorks.FirstParty",displayName="Spectrum optical devices",kind="core",targetModId="lightWorks",verified=true}
end
for _,def in ipairs(definitions) do
    local bulbType="lightWorks."..def.bulb
    local emissions={}
    if def.band then
        local spectrum={uva=0,uvb=0,uvc=0};spectrum[def.band]=1
        emissions.UV={intensity=def.uv,range=def.range,spectrum=spectrum}
    end
    API.registerBulb{item=bulbType,displayName=def.name.." bulb",tags={SPECTRUM=true,UV=def.band~=nil},
        compatibleLights={["lightWorks."..def.item]=true},
        visible={color={r=1,g=.8,b=.7},strengthMultiplier=1,distanceMultiplier=1},emissions=emissions,
        detection={visibilityMultiplier=1}}
    -- These are complete purpose-built devices, not UVC conversions of ordinary
    -- incandescent torches. Servicing accepts only their matching replacement.
    API.registerVerifiedLight("lightWorks.FirstParty",{item="lightWorks."..def.item,displayName=def.name,
        defaultBulb=bulbType,accepts=function(_,bulb)return bulb.item==bulbType end,
        emitter={class="specialist",range=def.range,strength=def.strength,cone=true,width=.7,nodes=3,falloff=.65},
        power={sizes={"AA","AA_PACK","LEGACY"},nominalCellCount=2,nominalVoltage=3,drainMultiplier=def.multiplier},
        physical={analogue="purpose-built optical device; shared vanilla housing",researchStatus="gameplay approximation"}})
end
return Content
