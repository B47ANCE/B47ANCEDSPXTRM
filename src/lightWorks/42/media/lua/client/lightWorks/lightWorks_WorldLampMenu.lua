require "lightWorks/lightWorks_API"
require "ISUI/ISWorldObjectContextMenu"

local lightWorks=lightWorks
lightWorks.WorldLampMenu=lightWorks.WorldLampMenu or {}
local Bridge=lightWorks.WorldLampMenu
local unpackValues=unpack or (table and table.unpack)
if not unpackValues then
    unpackValues=function(values,first,last)
        first=first or 1
        last=last or #values
        if first>last then return end
        return values[first],unpackValues(values,first+1,last)
    end
end

function Bridge.isRegisteredBulbType(typeName)
    if type(typeName)~="string" then return false end
    for fullType in pairs(lightWorks.Bulbs or {}) do
        if fullType==typeName or fullType:match("%.([^%.]+)$")==typeName then return true end
    end
    return false
end

function Bridge.install()
    if Bridge.installed then return true end
    if not ISWorldObjectContextMenu or type(ISWorldObjectContextMenu.doLightSwitchOption)~="function"
        or not luautils or type(luautils.stringStarts)~="function" then return false end
    local original=ISWorldObjectContextMenu.doLightSwitchOption
    Bridge.original=original
    ISWorldObjectContextMenu.doLightSwitchOption=function(...)
        local starts=luautils.stringStarts
        luautils.stringStarts=function(value,prefix)
            if prefix=="LightBulb" and Bridge.isRegisteredBulbType(value) then return true end
            return starts(value,prefix)
        end
        local results={pcall(original,...)}
        luautils.stringStarts=starts
        if not results[1] then
            print("[lightWorks][WorldLampMenu] vanilla lamp-menu callback failed safely: "..tostring(results[2]))
            return false
        end
        table.remove(results,1)
        return unpackValues(results)
    end
    Bridge.installed=true
    print("[lightWorks][WorldLampMenu] Registered bulbs enabled for vanilla fixtures")
    return true
end

Bridge.install()
if Events and Events.OnGameStart then Events.OnGameStart.Add(Bridge.install) end
return Bridge
