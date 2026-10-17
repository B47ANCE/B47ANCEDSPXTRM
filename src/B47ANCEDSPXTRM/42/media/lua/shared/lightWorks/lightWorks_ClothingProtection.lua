local API=require "lightWorks/lightWorks_API"
local Access=require "lightWorks/lightWorks_ItemAccess"
local Sunburn=require "lightWorks/lightWorks_Sunburn"
local Clothing={MAX_GARMENTS=64,MAX_PARTS=32}
local function finite(v) return type(v)=="number" and v==v and math.abs(v)<math.huge end
function Clothing.getProtection(character)
    if API.Config.EnableClothingSunProtection==false then return 0 end
    local countOk,total=Access.call(BloodBodyPartType and BloodBodyPartType.MAX,"index")
    if not countOk or not finite(total) or total<=0 or total>Clothing.MAX_PARTS then return nil end
    local got,worn=Access.call(character,"getWornItems");local sizeOk,size=Access.call(worn,"size")
    if not got or not sizeOk or not finite(size) or size<0 or size>Clothing.MAX_GARMENTS then return nil end
    local covered={}
    for index=0,size-1 do
        local entryOk,entry=Access.call(worn,"get",index)
        local itemOk,item=Access.call(entry,"getItem")
        if not entryOk or not itemOk then return nil end
        local partsOk,parts=Access.call(item,"getCoveredParts")
        if partsOk and parts then
            local read,n=Access.call(parts,"size")
            if not read or not finite(n) or n<0 or n>Clothing.MAX_PARTS then return nil end
            local visualOk,visual=Access.call(item,"getVisual")
            if n>0 and not visualOk then return nil end
            for partIndex=0,n-1 do
                local ok,part=Access.call(parts,"get",partIndex)
                local holeOk,hole=Access.call(visual,"getHole",part)
                local idOk,id=Access.call(part,"index")
                if not ok or not holeOk or not finite(hole) or not idOk or not finite(id) or id<0 or id>=total then return nil end
                -- Multiple layers never count the same body region twice.
                if hole<=0 then covered[id]=true end
            end
        end
    end
    local count=0;for _ in pairs(covered) do count=count+1 end
    local efficiency=API.Config.SunburnClothingProtection or .9
    return math.max(0,math.min(1,efficiency))*count/total
end
Sunburn.registerProtectionProvider("lightWorks.clothing",Clothing.getProtection)
API.ClothingProtection=Clothing
return Clothing
