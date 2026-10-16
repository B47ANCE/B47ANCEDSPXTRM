require "lightWorks/lightWorks_API"
local Patterns=require "lightWorks/lightWorks_Patterns"
local Access=require "lightWorks/lightWorks_ItemAccess"

local function tr(key,fallback)
    local get=rawget(_G,"getText")
    if type(get)~="function" or not key then return fallback end
    local ok,value=pcall(get,key)
    if ok and type(value)=="string" and value~="" and value~=key then return value end
    return fallback
end

local sequence=0
local function unwrap(entry)
    local ok,value=pcall(function()return entry and entry.items and entry.items[1] or entry end)
    return ok and value or nil
end
local function existingItemMenu(context,itemName)
    local ok,option=Access.call(context,"getOptionFromName",tostring(itemName));if not ok or not option then return nil end
    local read,subOption=pcall(function()return option.subOption end);if not read or subOption==nil then return nil end
    local found,menu=Access.call(context,"getSubMenu",subOption);return found and menu or nil
end
local function operationId(item)
    sequence=sequence+1
    local ok,id=Access.call(item,"getID")
    return "LW-PATTERN-"..tostring(ok and id or "unknown").."-"..tostring(sequence)
end
local function setPattern(player,item,id)
    if not player or not item or not Patterns.get(id) then return false end
    local op=operationId(item)
    if type(rawget(_G,"isClient"))=="function" and isClient()==true then
        local ok,itemId=Access.call(item,"getID")
        if not ok or type(itemId)~="number" or type(rawget(_G,"sendClientCommand"))~="function" then return false end
        return pcall(sendClientCommand,player,"lightWorks","setPattern",{itemId=itemId,patternId=id,operationId=op})
    end
    local ok=Patterns.set(item,id,op);return ok==true
end
local function addMenu(playerNum,context,rawItems)
    if lightWorks.Config.EnableLightPatterns==false or type(rawItems)~="table" then return end
    local player=type(rawget(_G,"getSpecificPlayer"))=="function" and getSpecificPlayer(playerNum) or nil;if not player then return end
    local item
    for _,entry in ipairs(rawItems)do local candidate=unwrap(entry);if candidate and lightWorks.isRegisteredLight(candidate)then item=candidate;break end end
    if not item then return end
    local _,name=Access.call(item,"getDisplayName");if not name then _,name=Access.call(item,"getName")end
    name=name or Access.fullType(item)or"Light"
    local itemMenu=existingItemMenu(context,name)
    if not itemMenu then
        local option=context:addOption(tostring(name),item,nil);itemMenu=ISContextMenu:getNew(context);context:addSubMenu(option,itemMenu)
    end
    local root=itemMenu:addOption(tr("ContextMenu_lightWorks_LightPattern","Light Pattern"),item,nil);local sub=ISContextMenu:getNew(context);itemMenu:addSubMenu(root,sub)
    local current=Patterns.getPatternId(item);local definitions=Patterns.all();local ids={};for id in pairs(definitions)do ids[#ids+1]=id end
    table.sort(ids,function(a,b)return tostring(tr(definitions[a].translationKey,definitions[a].displayName))<tostring(tr(definitions[b].translationKey,definitions[b].displayName))end)
    for _,id in ipairs(ids)do
        local label=tr(definitions[id].translationKey,definitions[id].displayName)
        local option=sub:addOption(label,player,setPattern,item,id)
        if id==current then option.notAvailable=true;option.toolTip={description=tr("ContextMenu_lightWorks_CurrentlySelected","Currently selected")} end
    end
end
local reported=false
local function safeAddMenu(...)
    local ok,err=pcall(addMenu,...);if not ok and not reported then reported=true;print("[lightWorks] Pattern menu integration error: "..tostring(err))end
end
if Events and Events.OnFillInventoryObjectContextMenu then Events.OnFillInventoryObjectContextMenu.Add(safeAddMenu)end
return {addMenu=addMenu,setPattern=setPattern}
