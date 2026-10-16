local apiPath,vanillaPath=arg[1],arg[2]
dofile(apiPath)
local realRequire=require
require=function(name) if name=="lightWorks/lightWorks_API" then return lightWorks end return realRequire(name) end
dofile(vanillaPath)

local regular=lightWorks.getLightProfile("Base.HandTorch").emitter
local heavy=lightWorks.getLightProfile("Base.Torch").emitter
local pen=lightWorks.getLightProfile("Base.PenLight").emitter
local lantern=lightWorks.getLightProfile("Base.Lantern_CraftedElectric").emitter
local weapon=lightWorks.getLightProfile("Base.GunLight").emitter
assert(heavy.range>regular.range and heavy.strength>regular.strength,
    "heavy-duty flashlights must have a stronger, longer emitter than regular flashlights")
assert(pen.range<regular.range and pen.strength<regular.strength and pen.width<regular.width,
    "penlights must use a compact narrow beam")
assert(lantern.cone==false and lantern.class=="standing_area","lanterns must use radial standing-light geometry")
assert(weapon.cone and weapon.width<regular.width,"weapon lights must use a focused cone")
assert(lightWorks.getEmitterTechnology("Base.HandTorch")=="xenon-incandescent")
assert(lightWorks.getOpticalProfile("Base.Torch").reflector=="large-adjustable")
assert(lightWorks.getOpticalProfile("Base.FlashLight_AngleHead_Army").filterSocket==true)
assert(lightWorks.getLightProfile("Base.HandTorch").power.nominalCellCount==2)
assert(lightWorks.getLightProfile("Base.HandTorch").power.sizes[2]=="AA_PACK",
    "regular flashlights must accept the explicit external AA pack connector")
assert(lightWorks.getLightProfile("Base.Torch").power.sizes[2]=="D_PACK",
    "heavy-duty flashlights must accept only the explicit external D pack connector")
print("lightWorks emitter-profile checks passed")
