require "lightWorks/lightWorks_API"
require "lightWorks/lightWorks_Vanilla"
require "lightWorks/lightWorks_UV"
require "lightWorks/lightWorks_EmissionSources"
local Sunburn=require "lightWorks/lightWorks_Sunburn"
require "lightWorks/lightWorks_LowPowerFlicker"
require "lightWorks/lightWorks_Patterns"
-- Canonical light definitions must exist before the powerWorks bridge walks the
-- registry. The bridge also repeats at game/server start for reviewed patches.
require "lightWorks/lightWorks_powerWorks"
require "lightWorks/lightWorks_WorldPower"
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
    local seen={}
    local function update(character)if character and not seen[character]then seen[character]=true;pcall(Sunburn.update,character)end end
    if type(getOnlinePlayers)=="function"then
        local ok,players=pcall(getOnlinePlayers);if ok and players then
            local sizeOk,size=pcall(function()return players:size()end);size=sizeOk and math.min(256,math.max(0,tonumber(size)or 0))or 0
            for index=0,size-1 do local got,player=pcall(function()return players:get(index)end);if got then update(player)end end
        end
    elseif type(getSpecificPlayer)=="function"then for index=0,3 do local ok,player=pcall(getSpecificPlayer,index);if ok then update(player)end end end
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
