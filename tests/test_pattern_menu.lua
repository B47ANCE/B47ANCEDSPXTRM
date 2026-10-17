local callback;local uuid=0
getRandomUUID=function()uuid=uuid+1;return string.format("00000000-0000-4000-8000-%012d",uuid)end
Events={OnFillInventoryObjectContextMenu={Add=function(fn)callback=fn end}}
local itemData={};local item={getID=function()return 7 end,getFullType=function()return"Test.PatternLight"end,getDisplayName=function()return"Pattern Light"end,getModData=function()return itemData end}
local player={};getSpecificPlayer=function()return player end
getText=function(key)
    local values={ContextMenu_lightWorks_LightPattern="Localized Pattern",
        ContextMenu_lightWorks_PatternSteady="Localized Steady",ContextMenu_lightWorks_PatternStrobe="Localized Strobe",
        ContextMenu_lightWorks_CurrentlySelected="Localized Current"}
    return values[key] or key
end
ISContextMenu={getNew=function()return{options={},addOption=function(self,label,target,fn,...)local o={label=label,target=target,fn=fn,args={...}};self.options[#self.options+1]=o;return o end,addSubMenu=function(self,o,sub)o.sub=sub end}end}
local root={options={},addOption=function(self,label,target,fn)local o={label=label,target=target,fn=fn};self.options[#self.options+1]=o;return o end,addSubMenu=function(self,o,sub)o.sub=sub end,getOptionFromName=function()return nil end}
lightWorks=nil;dofile(arg[1]);local API=lightWorks;API.registerLight{item="Test.PatternLight",tools=false}
package.loaded["lightWorks/lightWorks_API"]=API;package.loaded["lightWorks/lightWorks_ItemAccess"]=dofile(arg[2]);package.loaded["lightWorks/lightWorks_Patterns"]=dofile(arg[3])
local Menu=dofile(arg[4]);assert(type(callback)=="function")
assert(pcall(callback,0,root,{item})and #root.options==1)
local itemMenu=root.options[1].sub;assert(itemMenu.options[1].label=="Localized Pattern"and #itemMenu.options[1].sub.options==7)
local steady;for _,o in ipairs(itemMenu.options[1].sub.options)do if o.label=="Localized Steady"then steady=o end end
assert(steady and steady.notAvailable and steady.toolTip.description=="Localized Current","current pattern must be marked")
local strobe;for _,o in ipairs(itemMenu.options[1].sub.options)do if o.label=="Localized Strobe"then strobe=o end end
assert(strobe.fn(strobe.target,table.unpack(strobe.args))and API.Patterns.getPatternId(item)=="strobe")
isClient=function()return true end;local sent;sendClientCommand=function(p,m,c,a)sent={p,m,c,a}end
assert(Menu.setPattern(player,item,"pulse")and sent[2]=="lightWorks"and sent[3]=="setPattern"and sent[4].itemId==7)
local hostile=setmetatable({},{__index=function()error("hostile wrapper")end});assert(pcall(callback,0,root,{hostile}))
print("lightWorks nil-safe pattern selector checks passed")
package.loaded["lightWorks/lightWorks_PatternMenu"]=nil
local reconnected=require "lightWorks/lightWorks_PatternMenu"
assert(reconnected.setPattern(player,item,"beacon"));local firstId=sent[4].operationId
package.loaded["lightWorks/lightWorks_PatternMenu"]=nil
local secondClient=require "lightWorks/lightWorks_PatternMenu"
assert(secondClient.setPattern(player,item,"pulse"));local secondId=sent[4].operationId
assert(firstId~=secondId and #firstId<=128 and #secondId<=128,"fresh clients/reloads cannot reuse persisted operation IDs")
isClient=function()return false end
assert(API.Patterns.set(item,"beacon",firstId)and API.Patterns.set(item,"pulse",secondId))
assert(not API.Patterns.set(item,"steady",firstId),"the original request must still be rejected on replay")
