-- Lightweight host-Lua regression checks for API boundaries that do not depend
-- on the Project Zomboid runtime.
next=nil -- Build 42 Kahlua release compatibility.
local loadedModule=dofile("src/B47ANCEDSPXTRM/42/media/lua/shared/lightWorks/lightWorks_API.lua")

local lightWorks = lightWorks
assert(loadedModule==lightWorks,"API module must return its canonical namespace for require consumers")

local hostileItem = setmetatable({}, {
    __index = function()
        error("hostile inventory wrapper")
    end,
})

local ok, registered = pcall(lightWorks.isRegisteredLight, hostileItem)
assert(ok and registered == false, "unknown inventory wrappers must fail closed")

lightWorks.registerBulb({ item = "Test.SafeBulb" })
lightWorks.registerBulb({
    item = "Test.CanonicalUV",
    tags = { UV = true },
    visible = { color = { r = 1, g = 1, b = 1 }, strength = 0.25 },
    emissions = { UV = { intensity = 3, range = 20 } },
})
local canonicalUV=assert(lightWorks.getBulbProfile("Test.CanonicalUV"))
assert(canonicalUV.visible.color.r==lightWorks.UV_VISIBLE_COLOR.r
    and canonicalUV.visible.color.g==lightWorks.UV_VISIBLE_COLOR.g
    and canonicalUV.visible.color.b==lightWorks.UV_VISIBLE_COLOR.b,
    "UV registration must normalize visible RGB")
assert(canonicalUV.visible.strength==0.25 and canonicalUV.emissions.UV.intensity==3
    and canonicalUV.emissions.UV.range==20,
    "UV color normalization must preserve strength and mechanical emission specs")
canonicalUV.visible.color={r=0,g=1,b=0}
local renderedUV=lightWorks.getRenderedVisibleColor(canonicalUV)
assert(renderedUV.r==0.0 and renderedUV.g==0.0 and renderedUV.b==1.0,
    "final renderer boundary must enforce the canonical UV hue")
lightWorks.registerLight({
    item = "Test.ThrowingLight",
    tools = false,
    accepts = function()
        error("third-party callback failure")
    end,
})

local lightItem = {
    getFullType = function()
        return "Test.ThrowingLight"
    end,
}

ok, registered = pcall(lightWorks.isCompatible, lightItem, "Test.SafeBulb")
assert(ok and registered == false, "throwing accepts callback must fail closed")

local noTool, toolType = lightWorks.playerHasRequiredTool(nil, "Test.ThrowingLight")
assert(noTool == true and toolType == nil, "tool-free lights must remain serviceable")

assert(lightWorks.isRegisteredLight(nil) == false, "nil light lookup must be harmless")
assert(lightWorks.isRegisteredBulb(nil) == false, "nil bulb lookup must be harmless")

lightWorks.registerLight({ item = "Test.BadStateLight", tools = false })
local badStateLight = {
    getFullType = function() return "Test.BadStateLight" end,
    getModData = function() error("unavailable mod data") end,
}
ok, registered = pcall(lightWorks.getInstalledBulbType, badStateLight)
assert(ok and registered == "Base.LightBulb", "unavailable item state must fall back safely")

local function lightItem(fullType)
    local md = {}
    local item = {
        strength = 2.0,
        distance = 10,
        red = 1.0,
        green = 1.0,
        blue = 1.0,
        name = fullType,
    }
    function item:getFullType() return fullType end
    function item:getModData() return md end
    function item:getLightStrength() return self.strength end
    function item:setLightStrength(v) self.strength = v end
    function item:getLightDistance() return self.distance end
    function item:setLightDistance(v) self.distance = v end
    function item:getColorRed() return self.red end
    function item:setColorRed(v) self.red = v end
    function item:getColorGreen() return self.green end
    function item:setColorGreen(v) self.green = v end
    function item:getColorBlue() return self.blue end
    function item:setColorBlue(v) self.blue = v end
    function item:getScriptItem() return { getDisplayName = function() return fullType end } end
    function item:getName() return self.name end
    function item:setName(v) self.name = v end
    return item
end

lightWorks.registerBulb({
    item = "Test.RedBulb",
    displayName = "Red Test Bulb",
    visible = {
        color = { r = 1, g = 0, b = 0 },
        strengthMultiplier = 0.5,
        distanceMultiplier = 0.5,
    },
    detection = { visibilityMultiplier = 0.25 },
    emissions = { UV = { intensity = 0.75 } },
})
lightWorks.registerLight({ item = "Test.ServiceLight", defaultBulb = "Test.SafeBulb", tools = false })

local attachmentDef = { item = "Test.WearableLight", tools = false, attachment = { belt = true } }
lightWorks.registerLight(attachmentDef)
attachmentDef.attachment.belt = false
assert(lightWorks.getLightProfile("Test.WearableLight").attachment.belt == true,
    "registered attachment capabilities must not be mutable through caller tables")
assert(lightWorks.supportsWorldEmission("Test.WearableLight"),"registered lights should support world emission by default")
lightWorks.registerLight({item="Test.InventoryOnlyLight",tools=false,supportsWorldEmission=false})
assert(not lightWorks.supportsWorldEmission("Test.InventoryOnlyLight"),"verified providers must be able to opt unsafe items out")

local serviceLight = lightItem("Test.ServiceLight")
assert(lightWorks.getInstalledBulbType(serviceLight) == "Test.SafeBulb", "stock light must expose its default bulb")
local installed, oldType = lightWorks.installBulb(serviceLight, "Test.RedBulb")
assert(installed and oldType == "Test.SafeBulb", "installation must return the displaced default bulb")
assert(serviceLight.strength == 1.0 and serviceLight.distance == 5, "visible multipliers must use captured stock values")
assert(serviceLight.red == 1 and serviceLight.green == 1 and serviceLight.blue == 1,
    "emitted-light color must not tint the inventory item or world model")
local visibleColor = lightWorks.getInstalledBulb(serviceLight).visible.color
assert(visibleColor.r == lightWorks.UV_VISIBLE_COLOR.r
    and visibleColor.g == lightWorks.UV_VISIBLE_COLOR.g
    and visibleColor.b == lightWorks.UV_VISIBLE_COLOR.b,
    "UV emitted-light color must use the canonical renderer representation")
assert(lightWorks.getZombieVisibilityMultiplier(serviceLight) == 0.25, "detection semantics must remain independent")
assert(lightWorks.canEmit(serviceLight, "UV") == true, "UV emission must be queryable through the generic API")
assert(lightWorks.getEmission(serviceLight, "UV").intensity == 0.75, "emission payload must be preserved")

local removed, removedType = lightWorks.removeBulb(serviceLight)
assert(removed and removedType == "Test.RedBulb", "removal must return the physical bulb type")
assert(lightWorks.hasBulb(serviceLight) == false and serviceLight.strength == 0, "a bulbless light must be off")
assert(lightWorks.getZombieVisibilityMultiplier(serviceLight) == 0, "bulbless lights must have no detection signature")
assert(lightWorks.canEmit(serviceLight, "UV") == false, "bulbless lights must not emit")

local originalZombRand = ZombRand
ZombRand = function() return 0 end
assert(lightWorks.chooseWeightedBulb({ Zero = 0, Positive = 1 }) == "Positive", "zero roll must never select a zero-weight entry")
ZombRand = originalZombRand

assert(lightWorks.getSpawnBulbWeights("Test.Unknown", "default") == nil, "unknown spawn profiles must be harmless")

lightWorks.Config.ServiceTimeMultiplier=2.0
assert(lightWorks.getInstallBulbTime("Test.ServiceLight")==lightWorks.Config.DefaultHandInstallBulbTime*2,
    "sandbox servicing multiplier must affect action duration")
lightWorks.Config.RequireServiceTools=false
lightWorks.registerLight({item="Test.ToolLight",tools={"Base.Screwdriver"}})
assert(lightWorks.playerHasRequiredTool(nil,"Test.ToolLight")==true,
    "sandbox tool override must permit tool-free servicing")

print("lightWorks API regression checks passed")

-- API audit regression, host fixture only.

-- Current-build regression: native Item has getTorchDot but no setTorchDot.
lightWorks.registerBulb({item="Audit.Stock"})
lightWorks.registerBulb({item="Audit.Narrow",visible={torchDot=0.4}})
lightWorks.registerLight({item="Audit.Light",defaultBulb="Audit.Stock",tools=false})
local item={data={},name="Audit"}
function item:getFullType()return "Audit.Light"end
function item:getModData()return self.data end
function item:getName()return self.name end
function item:setName(n)self.name=n end
function item:getScriptItem()return {getDisplayName=function()return "Audit"end}end
function item:getLightStrength()return 1 end
function item:getLightDistance()return 8 end
function item:isTorchCone()return true end
function item:getTorchDot()return 0.96 end
function item:setLightStrength(v)end
function item:setLightDistance(v)end
function item:setTorchCone(v)end
assert(item.setTorchDot==nil)
assert(lightWorks.installBulb(item,"Audit.Narrow"))
assert(item.data.lightWorks.renderTorchDot==0.4,"profile torch dot was silently lost")
assert(item:getTorchDot()==0.96,"native/script torch dot must stay unchanged")
assert(lightWorks.installBulb(item,"Audit.Stock"))
assert(item.data.lightWorks.renderTorchDot==0.96,"stock bulb must restore native renderer dot")
