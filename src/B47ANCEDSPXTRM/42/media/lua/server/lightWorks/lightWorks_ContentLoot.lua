require "Items/ProceduralDistributions"
local API=require "lightWorks/lightWorks_API"
local Loot={}
local entries={
    {"MedicalStorageTools","lightWorks.UVAInspectionLamp",.5},
    {"MedicalStorageTools","lightWorks.UVCServiceLamp",.15},
    {"MedicalStorageTools","lightWorks.UVABulb",.7},
    {"MedicalStorageTools","lightWorks.UVCBulb",.3},
    {"GardenStoreTools","lightWorks.GrowLamp",.5},
    {"GardenStoreTools","lightWorks.GrowBulb",.7},
}
function Loot.install()
    if type(isClient)=="function" and isClient()==true then return false end
    API.applySandbox()
    local list=ProceduralDistributions and ProceduralDistributions.list
    if type(list)~="table" then return false end
    local multiplier=API.Config.OpticalDeviceLootMultiplier
    for _,entry in ipairs(entries) do
        local distribution=list[entry[1]];local items=distribution and distribution.items
        if type(items)=="table" then
            local found
            for index=1,#items,2 do if items[index]==entry[2] then found=index;break end end
            if found then items[found+1]=entry[3]*multiplier
            elseif multiplier>0 then items[#items+1]=entry[2];items[#items+1]=entry[3]*multiplier end
        end
    end
    return true
end
if Events and Events.OnPreDistributionMerge then Events.OnPreDistributionMerge.Add(Loot.install) end
return Loot
