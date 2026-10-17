require "TimedActions/ISTimedActionQueue"
local Access=require "lightWorks/lightWorks_ItemAccess"
local Water=require "lightWorks/lightWorks_WaterTreatmentAction"
local Menu={}
function Menu.add(playerNum,context,objects,test)
    if test or type(objects)~="table" or not context then return end
    local actor=type(getSpecificPlayer)=="function" and getSpecificPlayer(playerNum)
    if not actor then return end
    for index,object in ipairs(objects) do
        if index>64 then break end
        local got,item=Access.call(object,"getItem");local owner=got and item or object
        if Water.validate(actor,owner) then
            context:addOption(getText("ContextMenu_lightWorks_TreatWaterUVC"),actor,function(player,target)
                if Water.validate(player,target) then ISTimedActionQueue.add(Water.Action:new(player,target)) end
            end,owner)
            return
        end
    end
end
if Events and Events.OnFillWorldObjectContextMenu then Events.OnFillWorldObjectContextMenu.Add(Menu.add) end
return Menu
