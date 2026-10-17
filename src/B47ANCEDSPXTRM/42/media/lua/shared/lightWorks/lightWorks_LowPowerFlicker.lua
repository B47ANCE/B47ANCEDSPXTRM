local lightWorks=require "lightWorks/lightWorks_API"
local Flicker={}
local function finite(value)local n=tonumber(value);return n and n==n and n~=math.huge and n~=-math.huge and n or nil end
local function clamp(value,low,high)return math.max(low,math.min(high,finite(value)or low))end
local function hash(value)local h=5381;local text=tostring(value or"lightWorks");for index=1,#text do h=(h*33+string.byte(text,index))%2147483647 end;return h end
local function identity(item)
    if item and item.getID then local ok,value=pcall(function()return item:getID()end);if ok and value~=nil then return value end end
    if item and item.getFullType then local ok,value=pcall(function()return item:getFullType()end);if ok then return value end end
    return tostring(item)
end
local function now()
    -- The sandbox period is real milliseconds, independent of world speed.
    if type(getTimestampMs)=="function"then local ok,value=pcall(getTimestampMs);if ok and finite(value)then return finite(value)end end
    return math.floor((os.time and os.time()or 0)*1000)
end
function Flicker.getState(item,timestampMs)
    local result={known=false,flickering=false,visible=true,chargeFraction=nil}
    if lightWorks.Config.EnableLowBatteryFlicker==false then return result end
    local Power=(rawget(_G,"B47ANCEDPower")or rawget(_G,"powerWorks")or lightWorks.powerWorks)
    if type(Power)~="table"or type(Power.getConsumerPowerState)~="function"then return result end
    local ok,state=pcall(Power.getConsumerPowerState,item)
    if not ok or type(state)~="table"or state.known~=true then return result end
    result.known=true;result.chargeFraction=clamp(state.chargeFraction,0,1)
    if state.powered~=true then result.visible=false;return result end
    local threshold=clamp(lightWorks.Config.LowBatteryFlickerThreshold,0.001,1)
    if result.chargeFraction>threshold then return result end
    local period=math.max(500,finite(lightWorks.Config.LowBatteryFlickerPeriodMs)or 4000)
    local low=clamp(lightWorks.Config.LowBatteryFlickerMinimumOffFraction,0,.95)
    local high=clamp(lightWorks.Config.LowBatteryFlickerMaximumOffFraction,low,.95)
    local depletion=1-result.chargeFraction/threshold
    local offFraction=low+(high-low)*depletion
    local phase=((finite(timestampMs)or now())+hash(identity(item))%math.floor(period))%period
    result.flickering=true;result.periodMs=period;result.offFraction=offFraction
    result.visible=phase>=period*offFraction
    return result
end
function Flicker.shouldRender(item,timestampMs)local state=Flicker.getState(item,timestampMs);return state.visible,state end
lightWorks.LowPowerFlicker=Flicker
return Flicker
