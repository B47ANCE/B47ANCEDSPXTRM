local sourcePath = assert(arg[1], "colored-torch source path required")

local calls = { created = {}, added = {}, removed = {} }
IsoLightSource = {
    new = function(...)
        local source={ args={...} }
        calls.created[#calls.created+1]=source
        return source
    end,
}
local cell = {
    addLamppost=function(_,source) calls.added[#calls.added+1]=source end,
    removeLamppost=function(_,source) calls.removed[#calls.removed+1]=source end,
}
function cell:getGridSquare(x,y,z)
    return {
        x=x,y=y,z=z,
        testVisionAdjacent=function(self,dx,dy)
            return self.x < 12 and self.x+dx >= 12 and "Blocked" or "Clear"
        end,
    }
end
getCell=function() return cell end

ArrayList = { new = function()
    local values = {}
    return {
        add = function(_, value) values[#values + 1] = value end,
        size = function() return #values end,
        get = function(_, index) return values[index + 1] end,
    }
end }

Vector2 = { new = function() return {} end }
Events = {
    OnRenderTick = { Add = function() end },
    OnTick = { Add = function() end },
    OnGameStart = { Add = function() end },
    OnCreatePlayer = { Add = function() end },
}

local item = {
    modData = { lightWorks = { renderLightDistance=9, renderLightStrength=0.7, renderTorchCone=true, renderTorchDot=0.96 } },
    getFullType = function() return "Test.UVLight" end,
    getModData = function(self) return self.modData end,
    -- Some B42 light classes do not expose their item-level activation method
    -- even while present in IsoPlayer:getActiveLightItems().
    isActivated = function() error("activation accessor unavailable") end,
    setLightStrength = function(self, value) self.lightStrength = value end,
    getLightDistance = function() return 9 end,
    getLightStrength = function() return 0.7 end,
    isTorchCone = function() return true end,
    getTorchDot = function() return 0.96 end,
}

local weaponLight = {
    modData = { lightWorks = { renderLightDistance=7, renderLightStrength=0.6, renderTorchCone=true, renderTorchDot=0.95 } },
    getFullType = function() return "Base.GunLight" end,
    getModData = function(self) return self.modData end,
    getLightDistance = function() return 7 end,
    getLightStrength = function() return 0.6 end,
    isTorchCone = function() return true end,
    getTorchDot = function() return 0.95 end,
}
local weapon = {
    getFullType = function() return "Base.Pistol" end,
    isEmittingLight = function() return true end,
    getActiveLight = function() return weaponLight end,
    getLightDistance = function() return 7 end,
    getLightStrength = function() return 0.6 end,
    isTorchCone = function() return true end,
    getTorchDot = function() return 0.95 end,
    setLightStrength = function(self,value) self.lightStrength=value end,
}

local player = {
    getX = function() return 10.5 end,
    getY = function() return 20.5 end,
    getZ = function() return 2 end,
    getLookVector = function(_, vector)
        vector.getX = function() return 1 end
        vector.getY = function() return 0 end
        return vector
    end,
    getAimVector = function(_, vector)
        vector.getX = function() return 0 end
        vector.getY = function() return -1 end
        return vector
    end,
    getActiveLightItems = function(_, list) list:add(item); list:add(weapon) end,
    getAttachedItems = function() return nil end,
}

-- B42.20 AttachedItems:get(index) returns a wrapper; the renderer must use
-- getItemByIndex(index) to obtain the actual InventoryItem.
local attachedOnlyItem = {
    modData = { lightWorks = { renderLightDistance=5, renderLightStrength=0.4, renderTorchCone=true, renderTorchDot=0.9 } },
    getFullType = function() return "Test.AttachedUVLight" end,
    getModData = function(self) return self.modData end,
    isEmittingLight = function() return true end,
    setLightStrength = function(self, value) self.lightStrength = value end,
    getLightDistance = function() return 5 end,
    getLightStrength = function() return 0.4 end,
    isTorchCone = function() return true end,
    getTorchDot = function() return 0.9 end,
}
local attachedItems = {
    size = function() return 1 end,
    get = function() return { getItem=function() return attachedOnlyItem end } end,
    getItemByIndex = function() return attachedOnlyItem end,
    getLocation = function(_, candidate)
        if candidate == attachedOnlyItem then return "Belt Left" end
    end,
}
player.getAttachedItems = function() return attachedItems end

lightWorks = {
    Config = { EnableColoredLightRenderer=true, EnableAttachmentGeometry=true },
    MODDATA_KEY = "lightWorks",
    collectPlayerLights = function() return { item, attachedOnlyItem } end,
    getInstalledBulbType = function() return "Test.UVBulb" end,
    getInstalledBulb = function()
        return { tags={UV=true}, emissions={UV={intensity=1}}, visible = { color = { r=0.0, g=0.0, b=1.0 } } }
    end,
    getBulbProfile = function()
        return { visible = { color = { r=0.0, g=0.0, b=1.0 } } }
    end,
    isRegisteredLight = function(candidate)
        return candidate ~= weapon
    end,
    getLightProfile = function() return {} end,
    hasBulb = function() return true end,
    isBulbBurnedOut = function() return false end,
    applyVisibleProfile = function() end,
}

local realRequire = require
require = function(name)
    if name == "lightWorks/lightWorks_API" then return lightWorks end
    return realRequire(name)
end

getSpecificPlayer = function(index)
    if index == 0 then return player end
    return nil
end

dofile(sourcePath)
assert(lightWorks.refreshColoredTorches())
assert(#calls.created > 3, "handheld, weapon-attached, and body-attached lights must create colored world sources")
assert(#calls.added == #calls.created, "every colored source must be registered with IsoCell")
local args=calls.created[1].args
assert(args[4] == 0 and args[5] == 0 and args[6] == 1, "UV world source must use canonical pure-blue RGB")
for _,source in ipairs(calls.created) do
    assert(source.args[4]==0.0 and source.args[5]==0.0 and source.args[6]==1.0,
        "every UV render node must submit the exact canonical RGB independent of emitter strength")
end
for _,source in ipairs(calls.created) do
    assert(source.args[1] < 12 or source.args[2] ~= 20,
        "forward colored nodes must not be placed through the test wall")
end
local sawBarrelAlignedNode=false
for _,source in ipairs(calls.created) do
    if source.args[1]==10 and source.args[2]<20 then sawBarrelAlignedNode=true end
end
assert(sawBarrelAlignedNode,"weapon-light beam must follow aim/barrel vector rather than look vector")
assert(item.lightStrength == 0 and weapon.lightStrength == 0,
    "stock handheld and weapon emitters must be suppressed to prevent white washout")

local removedBefore=#calls.removed
lightWorks.Config.EnableColoredLightRenderer=false
assert(lightWorks.refreshColoredTorches()==false)
assert(#calls.removed>removedBefore and item.lightStrength==.7 and weapon.lightStrength~=0,
    "disabling rendering must remove owned lights and restore every suppressed native item, including weapons")
local cleaned=#calls.removed;lightWorks.refreshColoredTorches()
assert(#calls.removed==cleaned,"repeat disable must not remove sources twice")
lightWorks.Config.EnableColoredLightRenderer=true
assert(lightWorks.refreshColoredTorches()and item.lightStrength==0,"re-enable must bind fresh sources normally")
print("lightWorks colored IsoLightSource renderer and disable/re-enable checks passed")

local remoteItem={getFullType=function()return "Test.RemoteUV"end,getModData=function()return {}end,
    getLightStrength=function()return .5 end,setLightStrength=function(self,v)self.strength=v end}
local remote={getX=function()return 8 end,getY=function()return 18 end,getZ=function()return 2 end,
    getActiveLightItems=function(_,list)list:add(remoteItem)end,getLookVector=player.getLookVector}
getOnlinePlayers=function()return {size=function()return 1 end,get=function()return remote end}end
local addedBefore=#calls.added
assert(lightWorks.refreshColoredTorches() and #calls.added>addedBefore and remoteItem.strength==0,
    "nearby remote-player lights need custom presentation too")
getOnlinePlayers=function()return {size=function()return 0 end}end
assert(lightWorks.refreshColoredTorches() and remoteItem.strength==.5,"disconnect must restore suppressed remote item")

remote.getActiveLightItems=function()error("unavailable remote native list")end
getOnlinePlayers=function()return {size=function()return 1 end,get=function()return remote end}end
assert(lightWorks.refreshColoredTorches() and item.lightStrength==0,
    "one unavailable remote collection must not break local presentation or cleanup")
