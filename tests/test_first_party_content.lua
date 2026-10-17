local API=require "lightWorks/lightWorks_API"
require "lightWorks/lightWorks_Vanilla"
require "lightWorks/lightWorks_FirstPartyContent"
for _,pair in ipairs({{"UVAInspectionLamp","UVABulb","uva"},{"UVCServiceLamp","UVCBulb","uvc"},{"GrowLamp","GrowBulb"}}) do
    local light=assert(API.getLightProfile("lightWorks."..pair[1]))
    local bulb=assert(API.getBulbProfile(light.defaultBulb))
    assert(light.defaultBulb=="lightWorks."..pair[2] and light.power.nominalCellCount==2)
    assert(light.accepts({},bulb) and not light.accepts({},{item="Base.LightBulb"}))
    assert(API.isCompatible(light.item,bulb.item) and not API.isCompatible("Base.Torch",bulb.item),"specialist bulb cannot convert an ordinary housing")
    if pair[3] then
        assert(bulb.emissions.UV.spectrum[pair[3]]==1)
        for _,band in ipairs({"uva","uvb","uvc"}) do if band~=pair[3]then assert(bulb.emissions.UV.spectrum[band]==0)end end
    else assert(not bulb.emissions.UV,"grow lamp is visible illumination, not a UV lamp or crop mutation")end
end
package.preload["Items/ProceduralDistributions"]=function()return true end
ProceduralDistributions={list={MedicalStorageTools={items={"Base.Hammer",1}},GardenStoreTools={items={}}}}
local loot=require "lightWorks/lightWorks_ContentLoot"
assert(loot.install());local n=#ProceduralDistributions.list.MedicalStorageTools.items
assert(loot.install() and #ProceduralDistributions.list.MedicalStorageTools.items==n,"no duplicate loot registrations")
API.Config.OpticalDeviceLootMultiplier=0;assert(loot.install())
for i=3,n,2 do assert(ProceduralDistributions.list.MedicalStorageTools.items[i+1]==0)end
local file=assert(io.open("src/B47ANCEDSPXTRM/42/media/scripts/lightWorks_OpticalDevices.txt"));local text=file:read("*a");file:close()
for _,name in ipairs({"UVAInspectionLamp","UVCServiceLamp","GrowLamp","UVABulb","UVCBulb","GrowBulb"})do assert(text:find("item "..name,1,true))end
print("specialist device definitions, spectra, restricted replacements and idempotent sandbox-controlled loot pass")
