lightWorks={
    isRegisteredLight=function() return true end,
    hasBulb=function() return true end,
    isBulbBurnedOut=function() return false end,
    getEmission=function() return {class="STANDARD",intensity=1,range=10,spectrum={uva=1}} end,
    getBulbTag=function() return true end,
    getCustom=function() return nil end,
}
powerWorks={isRegisteredConsumer=function(item) return item.powerConsumer==true end,
    getConsumerPowerState=function(item) return {known=true,powered=item.powered==true} end}

require=function() return lightWorks end
getClimateManager=function() return {getDayLightStrength=function() return 0.8 end} end

dofile("src/lightWorks/42/media/lua/shared/lightWorks/lightWorks_UV.lua")

local outside={isOutside=function() return true end}
local inside={isOutside=function() return false end}
assert(lightWorks.UV.getSunlightExposure(outside).uv.natural==0.8)
assert(lightWorks.UV.getSunlightExposure(inside).uv.natural==0)

local vector={getX=function() return 1 end,getY=function() return 0 end}
local direction={ToVector=function() return vector end}
local emitterItem={isActivated=function() return true end}
local emptyParts={size=function() return 0 end}
local emptyAttached={size=function() return 0 end}
local player={
    getX=function() return 0 end,getY=function() return 0 end,getZ=function() return 0 end,
    getDir=function() return direction end,getPrimaryHandItem=function() return emitterItem end,
    getSecondaryHandItem=function() return nil end,getAttachedItems=function() return emptyAttached end,
}
emitterItem.getAllWeaponParts=function() return emptyParts end
local target={getX=function() return 5 end,getY=function() return 0 end,getZ=function() return 0 end,getSquare=function() return outside end}
local emitters=lightWorks.UV.collectPlayerEmitters(player)
local exposure=lightWorks.UV.getExposure(target,{emitters=emitters})
assert(#emitters==1 and exposure.uv.natural==0.8 and exposure.uv.artificial>0)
assert(exposure.uv.total==exposure.uv.natural+exposure.uv.artificial)
assert(exposure.uv.sources[1].sourceKind=="natural" and exposure.uv.sources[2].sourceKind=="artificial")
emitterItem.powerConsumer=true; emitterItem.powered=false
assert(#lightWorks.UV.collectPlayerEmitters(player)==0,"an empty registered consumer must not emit UV")
emitterItem.powered=true
assert(#lightWorks.UV.collectPlayerEmitters(player)==1,"confirmed powered consumers may emit UV")

local uvLamp={
    getBulbItem=function() return "ProjectNightfall.LightBulbUV" end,
    isActivated=function() return true end,
    getX=function() return 2 end,getY=function() return 2 end,getZ=function() return 0 end,
}
local highLamp={
    getBulbItem=function() return "ProjectNightfall.LightBulbUVHighOutput" end,
    isActivated=function() return true end,
    getX=function() return 3 end,getY=function() return 2 end,getZ=function() return 0 end,
}
local inactiveLamp={
    getBulbItem=function() return "ProjectNightfall.LightBulbUV" end,
    isActivated=function() return false end,
    getX=function() return 2 end,getY=function() return 2 end,getZ=function() return 0 end,
}
local objectList={size=function() return 2 end,get=function(_,index) return index==0 and uvLamp or index==1 and inactiveLamp or nil end}
local highObjectList={size=function() return 1 end,get=function() return highLamp end}
local lampSquare={getObjects=function() return objectList end}
local highSquare={getObjects=function() return highObjectList end}
getCell=function() return {getGridSquare=function(_,x,y,z)
    if x==2 and y==2 and z==0 then return lampSquare end
    if x==3 and y==2 and z==0 then return highSquare end
end} end
lightWorks.getBulbProfile=function(value)
    if value=="ProjectNightfall.LightBulbUV" then
        return {tags={UV=true},emissions={UV={class="STANDARD",intensity=1,range=9}}}
    end
    if value=="ProjectNightfall.LightBulbUVHighOutput" then
        return {tags={UV=true},emissions={UV={class="HIGH_OUTPUT",intensity=2,range=14}}}
    end
end
local stationary=lightWorks.UV.collectWorldEmitters({getX=function() return 2 end,getY=function() return 2 end,getZ=function() return 0 end},1)
assert(#stationary==2,"active placed UV lamps should be collected and inactive lamps excluded")
assert(stationary[1].directional==false and stationary[1].bulbType=="ProjectNightfall.LightBulbUV")
local lampTarget={getX=function() return 2 end,getY=function() return 2 end,getZ=function() return 0 end}
local stacked=lightWorks.UV.getArtificialExposure(lampTarget,stationary)
assert(#stacked.uv.sources==2 and stacked.uv.artificial>2.8,
    "standard and high-output lamp intensities should stack with distance falloff")

lightWorks.UV.registerExposureModifier("bad",function() return 0/0 end)
assert(lightWorks.UV.getSunlightExposure(outside).uv.natural==0.8,
    "non-finite modifiers must be ignored")
local malformed=lightWorks.UV.getArtificialExposure(target,{
    {owner=player,range=0,intensity=math.huge},
    {owner={getX=function() error("bad owner") end},range=10,intensity=1},
    "not-an-emitter",
})
assert(malformed.uv.artificial==0 and #malformed.uv.sources==0,
    "malformed third-party emitters must fail closed")

print("lightWorks UV exposure checks passed")
