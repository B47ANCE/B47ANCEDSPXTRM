local API=require "lightWorks/lightWorks_API"
local Clothing=require "lightWorks/lightWorks_ClothingProtection"
local Sunburn=require "lightWorks/lightWorks_Sunburn"
local function list(items)return {size=function()return #items end,get=function(_,i)return items[i+1]end}end
local p0={index=function()return 0 end};local p1={index=function()return 1 end}
BloodBodyPartType={MAX={index=function()return 4 end}}
local hole=0
local garment={getCoveredParts=function()return list({p0,p1})end,getVisual=function()return {getHole=function(_,p)return p==p1 and hole or 0 end}end}
local character={getWornItems=function()return list({{getItem=function()return garment end},{getItem=function()return garment end}})end}
assert(math.abs(Clothing.getProtection(character)-.45)<.00001,"duplicate layers cannot double coverage")
hole=1;assert(math.abs(Clothing.getProtection(character)-.225)<.00001,"holes must expose covered regions")
API.Config.EnableClothingSunProtection=false;assert(Clothing.getProtection(character)==0)
API.Config.EnableClothingSunProtection=true
BloodBodyPartType=nil
local _,_,complete=Sunburn.getProtection(character,{})
assert(complete==false,"unknown clothing surfaces cannot be treated as known bare skin")
print("clothing coverage, holes and unknown samples pass")
