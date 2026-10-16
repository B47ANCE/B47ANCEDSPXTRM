-- Manual developer helpers only. Nothing here runs a treatment, migration or
-- inventory mutation at load; it never installs a client gameplay RPC.
if type(isDebugEnabled)~="function" or isDebugEnabled()~=true then return {} end
local API=require "lightWorks/lightWorks_API"
local Consumers=require "lightWorks/lightWorks_ConsumerIntegrations"
local Access=require "lightWorks/lightWorks_ItemAccess"
local Harness={}
local function say(value) print("[lightWorks][Integration] "..tostring(value)) end
function Harness.status()
    local status=Consumers.refresh()
    say("Spectrum "..API.VERSION.." contract="..status.contractVersion)
    for _,name in ipairs({"nightfall","medical","water","waterEnabled","farming"}) do say(name.."="..tostring(status[name])) end
    say("API/source observations only. SP and dedicated verification remain NOT TESTED.")
    return status
end
function Harness.kit()
    if type(isClient)=="function" and isClient()==true then return false,"Use the server's authorized item-spawn tools for MP fixtures" end
    local player=type(getSpecificPlayer)=="function" and getSpecificPlayer(0)
    if not player then return false,"local SP player unavailable" end
    local kit=require "lightWorks/lightWorks_TestHarness"
    local ready,details=kit.giveKit(false)
    if not ready and details~="already granted" then return false,details end
    if type(details)=="table" and type(details.missing)=="table" and #details.missing>0 then
        return false,"base kit has unavailable items; inspect LWTestKit output"
    end
    local added=0
    for _,name in ipairs({"ProjectNightfall.LightBulbUV","ProjectNightfall.LightBulbUVHighOutput"}) do
        if API.getBulbProfile(name) and not API.inventoryContainsType(player,name) then
            if not Access.addItem(player,name) then return false,"item factory/inventory insertion failed: "..name end
            added=added+1
        end
    end
    say("Manual SP kit prepared; Nightfall bulbs added="..added)
    return true
end
function Harness.migrateHeld()
    if type(isClient)=="function" and isClient()==true then return false,"SP-only manual fixture helper" end
    local player=type(getSpecificPlayer)=="function" and getSpecificPlayer(0)
    local _,item=Access.call(player,"getPrimaryHandItem")
    if not item or not API.isRegisteredLight(item) then return false,"hold the disposable registered-light fixture" end
    local ok,reason=API.LegacyMigration.process(item,player)
    say("held migration="..tostring(ok).." "..tostring(reason))
    return ok,reason
end
function Harness.crop(crop)
    local result,reason=Consumers.cropLighting(crop)
    if not result then say(reason);return nil,reason end
    say("crop="..tostring(result.cropType).." complete="..tostring(result.complete)
        .." artificial="..tostring(result.artificialVisible).." growthEffect="..result.growthEffect)
    return result
end
LWIntegrationStatus=Harness.status
LWIntegrationKit=Harness.kit
LWIntegrationMigrateHeld=Harness.migrateHeld
LWIntegrationCropLighting=Harness.crop
return Harness
