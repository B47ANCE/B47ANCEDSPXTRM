lightWorks={Bulbs={
    ["Base.LightBulb"]={},
    ["ProjectNightfall.LightBulbUV"]={},
    ["ProjectNightfall.LightBulbUVHighOutput"]={},
    ["Compat.UVBulb"]={},
}}
local sawUV=false
luautils={stringStarts=function(value,prefix) return value:sub(1,#prefix)==prefix end}
ISWorldObjectContextMenu={doLightSwitchOption=function()
    sawUV=luautils.stringStarts("UVBulb","LightBulb")
    return "vanilla-result"
end}
Events={OnGameStart={Add=function() end}}
require=function() return true end

dofile(arg[1])
assert(lightWorks.WorldLampMenu.isRegisteredBulbType("UVBulb"))
assert(lightWorks.WorldLampMenu.isRegisteredBulbType("ProjectNightfall.LightBulbUVHighOutput"))
assert(ISWorldObjectContextMenu.doLightSwitchOption()=="vanilla-result")
assert(sawUV,"registered non-vanilla bulb should pass the scoped vanilla filter")
assert(luautils.stringStarts("UVBulb","LightBulb")==false,"vanilla helper must be restored")
print("lightWorks world-lamp menu checks passed")
