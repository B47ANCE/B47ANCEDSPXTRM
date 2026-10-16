require "lightWorks/lightWorks_API"

lightWorks.registerLightCompatibilityProvider({
    id="lightWorks.TargetMod",
    displayName="TARGET MOD verified lights",
    kind="patch",
    targetModId="TARGET_MOD_ID",
    verified=true,
})

lightWorks.registerVerifiedLight("lightWorks.TargetMod",{
    item="TargetModule.TargetFlashlight",
    displayName="Target Flashlight",
    defaultBulb="Base.LightBulb",
    tools=false,
    removeBulbTime=35,
    installBulbTime=45,
    -- Optional: use accepts(lightItem, bulbProfile) only when the hardware
    -- genuinely excludes some registered lightWorks bulbs/emission classes.
})
