local Operations=require "lightWorks/lightWorks_Operations"
local Notices=require "lightWorks/lightWorks_Notifications"
local lightWorks=require "lightWorks/lightWorks_API"
local Patterns={MAX_PATTERNS=32,MAX_OPERATIONS=32,registry={}}
local TAU=math.pi*2
local function finite(value)local n=tonumber(value);return n and n==n and n~=math.huge and n~=-math.huge and n or nil end
local function clamp(value,low,high)return math.max(low,math.min(high,finite(value)or low))end
local function copy(value,seen)if type(value)~="table"then return value end;seen=seen or{};if seen[value]then return seen[value]end;local out={};seen[value]=out;for k,v in pairs(value)do out[copy(k,seen)]=copy(v,seen)end;return out end
local function identity(item)
    if item and item.getID then local ok,value=pcall(function()return item:getID()end);if ok and value~=nil then return tostring(value)end end
    return tostring(item)
end
local function hash(value)local h=5381;for i=1,#value do h=(h*33+string.byte(value,i))%2147483647 end;return h end
local function now()
    if type(getGameTime)=="function"then
        local ok,gameTime=pcall(getGameTime)
        if ok and gameTime then local ageOk,hours=pcall(function()return gameTime:getWorldAgeHours()end);if ageOk and finite(hours)then return math.floor(hours*3600000)end end
    end
    if type(getTimestampMs)=="function"then local ok,value=pcall(getTimestampMs);if ok and finite(value)then return finite(value)end end
    return math.floor((os.time and os.time()or 0)*1000)
end
local function authority()if type(isServer)=="function"and isServer()==true then return true end;return not(type(isClient)=="function"and isClient()==true)end
local function modData(item)if not item or not item.getModData then return nil end;local ok,value=pcall(function()return item:getModData()end);return ok and type(value)=="table"and value or nil end

function Patterns.register(definition)
    assert(type(definition)=="table"and type(definition.id)=="string"and definition.id~="","pattern id required")
    assert(not Patterns.registry[definition.id],"duplicate light pattern: "..definition.id)
    local count=0;for _ in pairs(Patterns.registry)do count=count+1 end;assert(count<Patterns.MAX_PATTERNS,"light pattern limit reached")
    local def=copy(definition);def.periodMs=math.max(100,finite(def.periodMs)or 1000);def.dutyCycle=clamp(def.dutyCycle,0,1)
    assert(type(def.evaluate)=="function","pattern evaluate callback required")
    Patterns.registry[def.id]=def;return copy(def)
end
function Patterns.get(id)return Patterns.registry[id]and copy(Patterns.registry[id])or nil end
function Patterns.all()local result={};for id,def in pairs(Patterns.registry)do result[id]=copy(def)end;return result end
function Patterns.getPatternId(item)
    local data=modData(item);local state=data and data.lightWorksPattern
    if type(state)=="table"and state.schemaVersion==1 and Patterns.registry[state.id]then return state.id end
    local profile=lightWorks.getLightProfile and lightWorks.getLightProfile(item)or nil
    return profile and profile.emitter and Patterns.registry[profile.emitter.pattern]and profile.emitter.pattern or"steady"
end
function Patterns.evaluate(item,timestampMs)
    if lightWorks.Config.EnableLightPatterns==false then return 1,"steady"end
    local id=Patterns.getPatternId(item);local def=Patterns.registry[id]or Patterns.registry.steady
    local offset=0
    if def.alternating then offset=(hash(identity(item))%2)*def.periodMs*.5
    elseif def.itemPhase then offset=hash(identity(item))%math.floor(def.periodMs)end
    local data=modData(item);local state=data and data.lightWorksPattern
    local epoch=type(state)=="table"and finite(state.startedAtWorldAgeMs)or 0
    local explicit=finite(timestampMs);local time=explicit or now()
    local elapsed=explicit and time or (time-epoch)
    local phase=((elapsed+offset)%def.periodMs)/def.periodMs
    local ok,value=pcall(def.evaluate,phase,item,time);value=ok and finite(value)or 0
    return clamp(value,0,1),id
end
function Patterns.getDutyCycle(item)
    if lightWorks.Config.EnableLightPatterns==false then return 1 end
    local def=Patterns.registry[Patterns.getPatternId(item)]or Patterns.registry.steady
    return def and def.dutyCycle or 1
end
function Patterns.set(item,id,operationId)
    if not authority()then return false,"non-authority"end
    if lightWorks.Config.EnableLightPatterns==false then return false,"light patterns disabled"end
    if not lightWorks.isRegisteredLight(item)then return false,"registered light required"end
    if not Patterns.registry[id]then return false,"unknown light pattern"end
    if type(operationId)~="string"or operationId==""or #operationId>128 then return false,"operationId required"end
    local data=modData(item);if not data then return false,"item ModData unavailable"end
    local state=data.lightWorksPattern
    if state~=nil and(type(state)~="table"or state.schemaVersion~=1 or not Operations.validHistory(state.processedOperations))then return false,"unsupported pattern state"end
    state=state or{schemaVersion=1,id="steady",processedOperations={}};data.lightWorksPattern=state
    for _,existing in ipairs(state.processedOperations)do if existing==operationId then return false,"duplicate operation"end end
    local previous,previousEpoch=state.id,state.startedAtWorldAgeMs
    state.id=id;state.startedAtWorldAgeMs=now()
    local Power=(rawget(_G,"B47ANCEDPower")or rawget(_G,"powerWorks")or lightWorks.powerWorks)
    if type(Power)=="table"and type(Power.refreshConsumer)=="function"then
        local ok,refreshed=pcall(Power.refreshConsumer,item)
        if not ok or refreshed~=true then state.id=previous;state.startedAtWorldAgeMs=previousEpoch;return false,"power demand refresh failed"end
    end
    state.processedOperations[#state.processedOperations+1]=operationId
    while #state.processedOperations>Patterns.MAX_OPERATIONS do table.remove(state.processedOperations,1)end
    local result={id=id,dutyCycle=Patterns.getDutyCycle(item)}
    Notices.publish("pattern","selected",Notices.item(item),{pattern=id,operationId=operationId})
    return true,result
end

local function square(duty)return function(phase)return phase<duty and 1 or 0 end end
Patterns.register{id="steady",displayName="Steady",translationKey="ContextMenu_lightWorks_PatternSteady",periodMs=1000,dutyCycle=1,evaluate=function()return 1 end}
Patterns.register{id="strobe",displayName="Strobe",translationKey="ContextMenu_lightWorks_PatternStrobe",periodMs=500,dutyCycle=.5,evaluate=square(.5)}
Patterns.register{id="pulse",displayName="Pulse",translationKey="ContextMenu_lightWorks_PatternPulse",periodMs=2000,dutyCycle=.6,evaluate=function(phase)return .2+.8*(.5-.5*math.cos(TAU*phase))end}
Patterns.register{id="beacon",displayName="Beacon",translationKey="ContextMenu_lightWorks_PatternBeacon",periodMs=1200,dutyCycle=.18,evaluate=square(.18)}
Patterns.register{id="alternating",displayName="Alternating",translationKey="ContextMenu_lightWorks_PatternAlternating",periodMs=1000,dutyCycle=.5,alternating=true,evaluate=square(.5)}
Patterns.register{id="emergency",displayName="Emergency Double Flash",translationKey="ContextMenu_lightWorks_PatternEmergency",periodMs=1000,dutyCycle=.3,evaluate=function(phase)return(phase<.15 or(phase>=.30 and phase<.45))and 1 or 0 end}
local sos={{1,1},{0,1},{1,1},{0,1},{1,1},{0,3},{1,3},{0,1},{1,3},{0,1},{1,3},{0,3},{1,1},{0,1},{1,1},{0,1},{1,1},{0,7}}
local total=0;for _,part in ipairs(sos)do total=total+part[2]end
Patterns.register{id="sos",displayName="SOS",translationKey="ContextMenu_lightWorks_PatternSOS",periodMs=total*200,dutyCycle=15/total,evaluate=function(phase)local unit=phase*total;local cursor=0;for _,part in ipairs(sos)do cursor=cursor+part[2];if unit<cursor then return part[1]end end;return 0 end}
lightWorks.Patterns=Patterns
return Patterns
