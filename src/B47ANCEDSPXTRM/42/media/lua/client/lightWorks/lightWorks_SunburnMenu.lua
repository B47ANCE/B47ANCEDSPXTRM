local API=require "lightWorks/lightWorks_API"
local Sunburn=require "lightWorks/lightWorks_Sunburn"
local Menu={}
local function text(key,fallback,value)
    if type(getText)=="function" then
        local ok,result=pcall(getText,key,value)
        if ok and result and result~=key then return result end
    end
    return (fallback:gsub("%%1",function() return tostring(value or "") end))
end
function Menu.add(playerIndex,context,objects,test)
    if test or API.Config.EnableSunburn==false or type(getSpecificPlayer)~="function" then return end
    local player=getSpecificPlayer(playerIndex);if not player then return end
    local state=Sunburn.getState(player)
    if not state or not state.lastWorldAgeHours then return end
    local root=context:addOption(text("ContextMenu_lightWorks_SunExposure","Sun exposure"),nil,nil)
    if not ISContextMenu then return end
    local sub=ISContextMenu:getNew(context);context:addSubMenu(root,sub)
    for _,entry in ipairs({
        {"ContextMenu_lightWorks_SunDose","Accumulated sunlight dose: %1%",state.dose},
        {"ContextMenu_lightWorks_SunSeverity","Sunburn severity: %1%",state.severity},
        {"ContextMenu_lightWorks_SunProtection","Last sampled protection: %1%",state.lastProtection},
    }) do
        local option=sub:addOption(text(entry[1],entry[2],math.floor(entry[3]*100+.5)),nil,nil)
        option.notAvailable=true
    end
end
if Events and Events.OnFillWorldObjectContextMenu then Events.OnFillWorldObjectContextMenu.Add(Menu.add) end
return Menu
