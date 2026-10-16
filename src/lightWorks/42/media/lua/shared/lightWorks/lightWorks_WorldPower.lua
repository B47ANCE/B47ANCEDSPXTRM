local lightWorks=require "lightWorks/lightWorks_API"
local WorldPower={MAX_RADIUS=16,MAX_OBJECTS=256}

local function call(object,method,...)
    if not object then return false,nil end
    local ok,fn=pcall(function()return object[method]end)
    if not ok or type(fn)~="function"then return false,nil end
    return pcall(fn,object,...)
end
local function authority()
    if type(isServer)=="function"and isServer()==true then return true end
    return not(type(isClient)=="function"and isClient()==true)
end
local function nowHours()
    if type(getGameTime)~="function"then return nil end
    local ok,time=pcall(getGameTime);local read,hours=false,nil
    if ok then read,hours=call(time,"getWorldAgeHours")end
    hours=read and tonumber(hours)or nil;return hours and hours==hours and hours or nil
end
local function itemState(item,create)
    local ok,data=call(item,"getModData");if not ok or type(data)~="table"then return nil end
    local state=data.lightWorksWorldEmitter
    if state==nil and create then state={schemaVersion=1,active=false,processedOperations={}};data.lightWorksWorldEmitter=state end
    if type(state)=="table"and state.schemaVersion==1 then
        state.processedOperations=type(state.processedOperations)=="table"and state.processedOperations or{}
    end
    return type(state)=="table"and state.schemaVersion==1 and state or nil
end

function WorldPower.setActive(item,value,operationId)
    if not authority()or not item or not lightWorks.supportsWorldEmission(item)then return false,"unsupported"end
    if type(value)~="boolean"or type(operationId)~="string"or operationId==""or #operationId>128 then return false,"invalid request"end
    local state=itemState(item,true);if not state then return false,"world state unavailable"end
    for _,existing in ipairs(state.processedOperations)do if existing==operationId then return false,"duplicate operation"end end
    if value then
        if lightWorks.hasBulb and not lightWorks.hasBulb(item)then return false,"bulb required"end
        if lightWorks.isBulbBurnedOut and lightWorks.isBulbBurnedOut(item)then return false,"bulb burned out"end
        local Power=rawget(_G,"powerWorks")or lightWorks.powerWorks
        if type(Power)~="table"or type(Power.getConsumerPowerState)~="function"then return false,"power state unavailable"end
        local ok,power=pcall(Power.getConsumerPowerState,item)
        if not ok or type(power)~="table"or power.known~=true or power.powered~=true then return false,"charged battery required"end
    end
    state.active=value;state.lastPowerUpdateHours=nowHours()or state.lastPowerUpdateHours
    state.processedOperations[#state.processedOperations+1]=operationId
    while #state.processedOperations>32 do table.remove(state.processedOperations,1)end
    call(item,"setActivated",value);call(item,"syncItemFields")
    return true,{active=value,operationId=operationId}
end

function WorldPower.prepareBacking(backing,item)
    if not backing or not item then return false,"missing backing"end
    local state=itemState(item,false);local enabled=state and state.active==true or false
    if enabled then
        local Power=rawget(_G,"powerWorks")or lightWorks.powerWorks
        local ok,power=false,nil
        if type(Power)=="table"and type(Power.getConsumerPowerState)=="function"then ok,power=pcall(Power.getConsumerPowerState,item)end
        enabled=ok and type(power)=="table"and power.known==true and power.powered==true
    end
    local set=call(backing,"setMovedThumpable",enabled)
    return set==true,enabled
end

function WorldPower.updateItem(item,worldAgeHours)
    if not authority()or not item or not lightWorks.supportsWorldEmission(item)then return false,"unsupported"end
    local state=itemState(item);local now=tonumber(worldAgeHours)or nowHours()
    if not state or not now then return false,"world state unavailable"end
    local previous=tonumber(state.lastPowerUpdateHours);state.lastPowerUpdateHours=now
    if not previous or now<=previous or state.active~=true then return true,0 end
    local Power=rawget(_G,"powerWorks")or lightWorks.powerWorks
    if type(Power)~="table"or type(Power.getConsumerEnergyRatePerHour)~="function"or type(Power.consumeEnergy)~="function"then
        return false,"powerWorks world-consumption API unavailable"
    end
    local rate=Power.getConsumerEnergyRatePerHour(item)
    if type(rate)~="number"or rate<0 then return false,"consumption rate unavailable"end
    local elapsed=math.min(now-previous,24*365*10)
    local consumed,remaining=Power.consumeEnergy(item,rate*elapsed)
    if consumed~=true then return false,remaining or"energy consumption failed"end
    call(item,"syncItemFields")
    local powerOk,powerState=pcall(Power.getConsumerPowerState,item)
    if powerOk and type(powerState)=="table"and powerState.known==true and powerState.powered~=true then
        state.active=false;call(item,"setActivated",false)
    end
    return true,rate*elapsed,remaining
end

local function players()
    local result={}
    if type(getOnlinePlayers)=="function"then
        local ok,list=pcall(getOnlinePlayers);local count
        if ok then local countOk;countOk,count=call(list,"size");if not countOk then count=nil end end
        for index=0,math.min(64,math.max(0,tonumber(count)or 0))-1 do local got,p=call(list,"get",index);if got and p then result[#result+1]=p end end
    elseif type(getSpecificPlayer)=="function"then for index=0,3 do local p=getSpecificPlayer(index);if p then result[#result+1]=p end end end
    return result
end

function WorldPower.reconcile()
    if not authority()or type(getCell)~="function"then return 0 end
    local cell=getCell();local seen={};local processed=0;local now=nowHours();if not cell or not now then return 0 end
    for _,player in ipairs(players())do
        local _,px=call(player,"getX");local _,py=call(player,"getY");local _,pz=call(player,"getZ")
        px,py,pz=tonumber(px),tonumber(py),tonumber(pz)
        if px and py and pz then
            px,py,pz=math.floor(px),math.floor(py),math.floor(pz)
            for x=px-WorldPower.MAX_RADIUS,px+WorldPower.MAX_RADIUS do for y=py-WorldPower.MAX_RADIUS,py+WorldPower.MAX_RADIUS do
                if(x-px)^2+(y-py)^2<=WorldPower.MAX_RADIUS^2 then
                    local _,square=call(cell,"getGridSquare",x,y,pz);local _,objects=call(square,"getWorldObjects");local _,count=call(objects,"size")
                    for index=0,math.min(512,math.max(0,tonumber(count)or 0))-1 do
                        local got,backing=call(objects,"get",index);local itemOk,item=false,nil
                        if got then itemOk,item=call(backing,"getItem")end
                        if itemOk and item and not seen[item]and lightWorks.supportsWorldEmission(item)then
                            seen[item]=true;WorldPower.updateItem(item,now);WorldPower.prepareBacking(backing,item);processed=processed+1
                            if processed>=WorldPower.MAX_OBJECTS then return processed end
                        end
                    end
                end
            end end
        end
    end
    return processed
end

if Events and Events.EveryTenMinutes then Events.EveryTenMinutes.Add(WorldPower.reconcile)end
lightWorks.WorldPower=WorldPower
return WorldPower
