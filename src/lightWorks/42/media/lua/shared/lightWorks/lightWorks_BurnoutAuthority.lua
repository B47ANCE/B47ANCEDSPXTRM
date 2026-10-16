local API=require "lightWorks/lightWorks_API"
require "lightWorks/lightWorks_Vanilla"
local Access=require "lightWorks/lightWorks_ItemAccess"
if API.Burnout then return API.Burnout end
local Burnout={}
local lastHours,accumulator=nil,0

local function authority()
    if type(isServer)=="function" and isServer()==true then return true end
    return not(type(isClient)=="function" and isClient()==true)
end
local function finite(value)
    return type(value)=="number" and value==value and math.abs(value)<math.huge
end
local function players()
    local result,seen={},{}
    local function add(player)
        if player and not seen[player] then seen[player]=true;result[#result+1]=player end
    end
    if type(getOnlinePlayers)=="function" then
        local ok,list=pcall(getOnlinePlayers)
        if ok then
            local got,count=Access.call(list,"size")
            if got and finite(count) then
                for index=0,math.min(256,math.max(0,count))-1 do
                    local read,player=Access.call(list,"get",index);if read then add(player) end
                end
            end
        end
    end
    -- Dedicated authority never requires a local player. SP also works when the
    -- global online-player accessor exists but returns an empty collection.
    if not(type(isServer)=="function" and isServer()==true) and type(getSpecificPlayer)=="function" then
        for index=0,3 do add(getSpecificPlayer(index)) end
    end
    return result
end

function Burnout.onTick()
    if not authority() or type(getGameTime)~="function" then return end
    local time=getGameTime();local ok,hours=Access.call(time,"getWorldAgeHours")
    if not ok or not finite(hours) then return end
    local previous=lastHours;lastHours=hours
    if not previous or hours<=previous then return end
    accumulator=accumulator+math.min(10,(hours-previous)*60)
    if accumulator<API.Config.BurnoutCheckEveryGameMinutes then return end
    local elapsed=accumulator;accumulator=0
    local seen={}
    for _,player in ipairs(players()) do
        for _,item in ipairs(API.collectPlayerLights(player)) do
            if not seen[item] then
                seen[item]=true
                local before=API.getBulbBurnMinutes(item)
                local burned,brokenType=API.updateBulbBurnout(item,elapsed)
                if burned then
                    local output=Access.addItem(player,brokenType)
                    if not output then print("[lightWorks] Broken bulb output requires inspection; no automatic retry") end
                end
                if burned or API.getBulbBurnMinutes(item)~=before then
                    local parent=Access.findWeaponForPart(player,item)
                    if not Access.syncServiceState(player,item,parent) then
                        print("[lightWorks] Authority burnout state sync failed; inspect before retry")
                    end
                end
            end
        end
    end
end

if Events and Events.OnTick then Events.OnTick.Add(Burnout.onTick) end
API.Burnout=Burnout
return Burnout
