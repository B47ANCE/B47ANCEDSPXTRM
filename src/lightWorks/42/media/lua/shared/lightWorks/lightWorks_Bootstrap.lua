require "lightWorks/lightWorks_API"
require "lightWorks/lightWorks_Vanilla"
require "lightWorks/lightWorks_LegacyMigration"
require "lightWorks/lightWorks_UV"
require "lightWorks/lightWorks_EmissionSources"
require "lightWorks/lightWorks_ConsumerIntegrations"
require "lightWorks/lightWorks_Fixtures"
require "lightWorks/lightWorks_Lasers"
local Sunburn=require "lightWorks/lightWorks_Sunburn"
require "lightWorks/lightWorks_ClothingProtection"
require "lightWorks/lightWorks_LowPowerFlicker"
require "lightWorks/lightWorks_Patterns"
-- Canonical light definitions must exist before the powerWorks bridge walks the
-- registry. The bridge also repeats at game/server start for reviewed patches.
require "lightWorks/lightWorks_powerWorks"
require "lightWorks/lightWorks_WorldPower"
require "lightWorks/lightWorks_WorldDrop"
require "lightWorks/lightWorks_BurnoutAuthority"
require "lightWorks/lightWorks_LightCatalog"
require "lightWorks/lightWorks_AttachmentProfiles"

local function buildCatalog(reason)
    if lightWorks.Config.EnableAutomaticDiscovery==false then return end
    if lightWorks.LightCatalog.isBuilt() then return end
    local ok,result=lightWorks.LightCatalog.build(reason)
    if not ok then
        print("[lightWorks] Light catalog deferred: "..tostring(result))
        return
    end
    local summary=lightWorks.LightCatalog.summary()
    print(string.format("[lightWorks] Light catalog built: candidates=%d verified=%d awaitingReview=%d",summary.total,summary.verified,summary.review))
end

if Events and Events.OnGameStart then Events.OnGameStart.Add(function() buildCatalog("OnGameStart") end) end
if Events and Events.OnServerStarted then Events.OnServerStarted.Add(function() buildCatalog("OnServerStarted") end) end

local sunburnFrame=0
if Events and Events.OnTick then Events.OnTick.Add(function()
    sunburnFrame=sunburnFrame+1;if sunburnFrame%60~=0 then return end
    if type(isClient)=="function" and isClient()==true and not(type(isServer)=="function" and isServer()==true) then return end
    for _,character in ipairs(require("lightWorks/lightWorks_Players").collect(false)) do Sunburn.update(character) end
end)end

if type(isDebugEnabled)~="function" or isDebugEnabled()==true then
    function LWExportLightReview(filename)
        buildCatalog("developer-export")
        local ok,result=lightWorks.LightCatalog.exportReviewReport(filename)
        print("[lightWorks] Light review export: "..tostring(ok and result or ("FAILED: "..tostring(result))))
        return ok,result
    end
end

print("[lightWorks] v" .. tostring(lightWorks.VERSION) .. " loaded")
