require "lightWorks/lightWorks_API"
local LowPowerFlicker=require "lightWorks/lightWorks_LowPowerFlicker"
local Patterns=require "lightWorks/lightWorks_Patterns"

-- B42.20.3 hardcodes player TorchInfo to warm white and does not expose
-- LightingJNI to Lua. lightWorks therefore suppresses the stock item emitter
-- and renders a bounded chain of Lua-supported colored IsoLightSource records.
local lightWorks = lightWorks
local states = setmetatable({}, {__mode="k"})
local nextId = 20000
local reportedFailure = false
local lastReports = setmetatable({}, {__mode="k"})

local function clamp01(value, fallback)
    value = tonumber(value)
    if value == nil then value = fallback end
    return math.max(0.0, math.min(1.0, value))
end

local function renderedColor(bulb)
    if not bulb then return nil end
    if lightWorks.getRenderedVisibleColor then return lightWorks.getRenderedVisibleColor(bulb) end
    return bulb.visible and bulb.visible.color or nil
end

local function callValue(object, method, fallback)
    local ok, value = pcall(function() return object[method](object) end)
    if not ok or value == nil then return fallback end
    return value
end

local function attachmentLocation(player, item)
    local attached = player and player.getAttachedItems and player:getAttachedItems() or nil
    if not attached or not attached.getLocation then return nil end
    local ok, location = pcall(function() return attached:getLocation(item) end)
    return ok and location or nil
end

local function isActive(item)
    -- isEmittingLight() is the engine's final item-level decision after
    -- activation, charge, and equip state have been combined.
    local ok, active = pcall(function() return item:isEmittingLight() end)
    if ok and active==true then return true end
    ok, active = pcall(function() return item:isActivated() end)
    if not ok and item.getActivated then ok, active = pcall(function() return item:getActivated() end) end
    return ok and active == true
end

local function clearSources(state)
    local cell=getCell and getCell() or nil
    if cell and state.sources then
        for _,source in ipairs(state.sources) do pcall(function() cell:removeLamppost(source) end) end
    end
    state.sources={}
    state.sourceSignature=nil
end

local function restoreState(state)
    clearSources(state)
    for item,strength in pairs(state.suppressed or {}) do
        pcall(function() item:setLightStrength(strength) end)
    end
    state.suppressed=nil
    state.active=false
end

local function emitterProfileItem(renderItem)
    if lightWorks.isRegisteredLight(renderItem) then return renderItem end
    -- B42.20 adds the HandWeapon itself to getActiveLightItems(), while its
    -- light definition, bulb state, and power state live on getActiveLight().
    local ok,part=pcall(function() return renderItem:getActiveLight() end)
    if ok and part and lightWorks.isRegisteredLight(part) then return part end
    return renderItem
end

local function ensureState(item)
    local bulbType = lightWorks.getInstalledBulbType(item)
    local state = states[item]
    if not state then
        state = {id=nextId, customId=nextId, active=false}
        nextId = nextId + 1
        states[item] = state
    end
    if state.bulbType ~= bulbType or not state.active then
        state.bulbType = bulbType
        local md = item:getModData()
        local saved = md and md[lightWorks.MODDATA_KEY] or nil
        local profile=lightWorks.getLightProfile(item)
        local emitter=profile and profile.emitter or nil
        local bulb=lightWorks.getBulbProfile(bulbType)
        local visible=bulb and bulb.visible or nil
        local distanceMultiplier=tonumber(visible and visible.distanceMultiplier) or 1
        local strengthMultiplier=tonumber(visible and visible.strengthMultiplier) or 1
        state.dist = emitter and tonumber(emitter.range) and tonumber(emitter.range)*distanceMultiplier
            or tonumber(saved and saved.renderLightDistance)
            or tonumber(callValue(item,"getLightDistance",state.dist or 6)) or 6
        state.strength = emitter and tonumber(emitter.strength) and tonumber(emitter.strength)*strengthMultiplier
            or tonumber(saved and saved.renderLightStrength)
            or tonumber(callValue(item,"getLightStrength",state.strength or 0.7)) or 0.7
        local savedCone = saved and saved.renderTorchCone
        if emitter and emitter.cone~=nil then state.cone=emitter.cone==true
        elseif savedCone ~= nil then state.cone = savedCone == true
        else state.cone = callValue(item,"isTorchCone",true) == true end
        state.dot = tonumber(saved and saved.renderTorchDot)
            or tonumber(callValue(item,"getTorchDot",0.96)) or 0.96
        state.width=math.max(0.1,tonumber(emitter and emitter.width) or 0.7)
        state.nodes=math.max(1,math.min(8,math.floor(tonumber(emitter and emitter.nodes) or 4)))
        state.falloff=math.max(0.1,math.min(1,tonumber(emitter and emitter.falloff) or 0.72))
    end
    return state
end

local function playerForward(player)
    local ok, vector = pcall(function() return player:getLookVector(Vector2.new()) end)
    if ok and vector then return vector:getX(), vector:getY() end
    local direction = player and player.getDir and player:getDir() or nil
    if direction and direction.ToVector then
        local vec = direction:ToVector()
        return vec:getX(), vec:getY()
    end
    return 0.0, -1.0
end

local function weaponForward(player)
    local aiming=nil
    if player and player.isAiming then pcall(function() aiming=player:isAiming() end) end
    if aiming~=false and player and player.getAimVector and Vector2 and Vector2.new then
        local ok,vector=pcall(function() return player:getAimVector(Vector2.new()) end)
        if ok and vector then
            local x,y=tonumber(vector:getX()),tonumber(vector:getY())
            local length=x and y and math.sqrt(x*x+y*y) or 0
            if length>0.0001 then return x/length,y/length end
        end
    end
    if player and player.getForwardDirection then
        local ok,vector=pcall(function() return player:getForwardDirection() end)
        if ok and vector then
            local x,y=tonumber(vector:getX()),tonumber(vector:getY())
            local length=x and y and math.sqrt(x*x+y*y) or 0
            if length>0.0001 then return x/length,y/length end
        end
    end
    return playerForward(player)
end

local function isWeaponEmitter(renderItem,profileItem)
    if not renderItem or renderItem==profileItem or not renderItem.getActiveLight then return false end
    local ok,activeLight=pcall(function() return renderItem:getActiveLight() end)
    return ok and activeLight==profileItem
end

local function renderGeometry(player, item, state, location, renderItem)
    local x, y, z = player:getX(), player:getY(), player:getZ()
    local fx, fy
    if isWeaponEmitter(renderItem,item) then fx,fy=weaponForward(player)
    else fx,fy=playerForward(player) end
    local angleX, angleY = fx, fy
    local dist, strength, cone, dot = state.dist, state.strength, state.cone, state.dot
    local profile = lightWorks.getLightProfile(item)
    local attachment = profile and profile.attachment or nil

    if lightWorks.Config.EnableAttachmentGeometry~=false and location and attachment and attachment.geometry == "down" then
        -- A straight flashlight hanging from a belt points at the ground. Model
        -- that as a small local pool rather than a forward-facing cone.
        cone = false
        dist = math.min(3.0, dist)
        strength = math.min(0.55, strength * 0.70)
        dot = 0.0
    elseif lightWorks.Config.EnableAttachmentGeometry~=false and location and attachment and attachment.geometry == "outward" then
        -- Angle-headed lights point away from the hip/webbing side.
        local lower = string.lower(tostring(location))
        local left = string.find(lower,"left",1,true) ~= nil
        angleX, angleY = left and -fy or fy, left and fx or -fx
        x, y = x + angleX * 0.25, y + angleY * 0.25
        cone = true
    end
    return x,y,z,angleX,angleY,dist,strength,cone,dot
end

local function renderWorldSources(state,x,y,z,ax,ay,dist,strength,cone,r,g,b,lockChroma)
    local cell=getCell and getCell() or nil
    if not cell or type(IsoLightSource)~="table" or type(IsoLightSource.new)~="function" then return false end
    local baseX,baseY,baseZ=math.floor(x),math.floor(y),math.floor(z)
    local reachable={{x=baseX,y=baseY,distance=0}}
    if cone then
        local previous=nil
        pcall(function() previous=cell:getGridSquare(baseX,baseY,baseZ) end)
        local lastX,lastY=baseX,baseY
        for step=1,math.max(1,math.floor(dist)) do
            local sx=math.floor(x+ax*step)
            local sy=math.floor(y+ay*step)
            if sx~=lastX or sy~=lastY then
                local square=nil
                pcall(function() square=cell:getGridSquare(sx,sy,baseZ) end)
                local blocked=false
                if previous and square then
                    local ok,value=pcall(function() return previous:CalculateVisionBlocked(square) end)
                    if not ok then ok,value=pcall(function() return previous:isBlockedTo(square) end) end
                    blocked=ok and value==true
                elseif cell.getGridSquare then
                    -- A missing square is outside the loaded/valid beam path.
                    blocked=true
                end
                if blocked then break end
                reachable[#reachable+1]={x=sx,y=sy,distance=step}
                previous=square or previous
                lastX,lastY=sx,sy
            end
        end
    end
    local pointSignature={}
    for _,point in ipairs(reachable) do pointSignature[#pointSignature+1]=point.x..","..point.y end
    local signature=string.format("%d:%d:%d:%.2f:%.2f:%.2f:%.2f:%.2f:%.2f:%.2f:%s:%s",
        baseX,baseY,baseZ,ax,ay,dist,strength,r,g,b,tostring(cone),table.concat(pointSignature,";"))
    if state.sourceSignature==signature then return true end
    clearSources(state)
    local count=cone and math.min(state.nodes or 4,#reachable) or 1
    local used={}
    for index=1,count do
        local reachableIndex=count==1 and 1 or math.floor(1+(index-1)*(#reachable-1)/(count-1)+0.5)
        local point=reachable[reachableIndex]
        local sx,sy=point.x,point.y
        local key=sx..":"..sy
        if not used[key] then
            used[key]=true
            -- The near node guarantees illumination in small rooms. Farther
            -- nodes broaden the beam only along squares proven visible.
            local width=state.width or 0.7
            local radius=index==1 and math.max(1,math.ceil(1+width))
                or (cone and math.max(1,math.ceil(dist/count*width)) or math.max(2,math.min(6,math.ceil(dist))))
            local progress=count==1 and 0 or (index-1)/(count-1)
            local level=math.max(0.06,math.min(1.0,strength))*((state.falloff or 0.72)^progress)
            if index==1 and cone then level=level*0.55 end
            local sourceR,sourceG,sourceB=r*level,g*level,b*level
            if lockChroma then
                -- IsoLightSource has no separate intensity argument: scaling RGB
                -- changes how ambient light mixes with it and makes identical UV
                -- bulbs appear to have different hues. Keep UV chroma at its
                -- canonical value and express strength/falloff through coverage.
                sourceR,sourceG,sourceB=r,g,b
                radius=math.max(1,math.ceil(radius*math.sqrt(level)))
            end
            local source=IsoLightSource.new(sx,sy,math.floor(z),sourceR,sourceG,sourceB,radius)
            cell:addLamppost(source)
            state.sources[#state.sources+1]=source
        end
    end
    state.sourceSignature=signature
    return true
end

local function nativeIdsByItem(player, playerIndex)
    local result, active = {}, {}
    local items = ArrayList.new()
    player:getActiveLightItems(items)
    local count = math.min(items:size(),4)
    for index=0,count-1 do
        local item=items:get(index)
        result[item] = playerIndex*4+index+1
        active[#active+1]={item=item,id=playerIndex*4+index+1}
    end
    return result,active
end

local function mountedPlayerLights(player)
    local result={}
    local function add(item) if item then result[#result+1]=item end end
    local ok,item=pcall(function() return player:getPrimaryHandItem() end); if ok then add(item) end
    ok,item=pcall(function() return player:getSecondaryHandItem() end); if ok then add(item) end
    local attached=nil
    ok,attached=pcall(function() return player:getAttachedItems() end)
    if ok and attached then
        local size=0
        pcall(function() size=attached:size() end)
        for index=0,size-1 do
            local attachedItem=nil
            -- AttachedItems:get(index) returns an AttachedItem wrapper in
            -- B42.20.  The inventory item itself is exposed separately.
            pcall(function() attachedItem=attached:getItemByIndex(index) end)
            add(attachedItem)
        end
    end
    return result
end

local function refreshPlayer(player, playerIndex, seen)
    if not player then return end
    local nativeIds,activeItems = nativeIdsByItem(player,playerIndex)
    local candidates,candidateIds,candidateSeen,mounted={},{},{},{}
    -- Process these exact Java objects first. Looking the same item up through
    -- an inventory traversal can produce a distinct Kahlua wrapper whose table
    -- identity does not match the active-light wrapper.
    for _,entry in ipairs(activeItems) do
        candidates[#candidates+1]=entry.item
        candidateIds[entry.item]=entry.id
        candidateSeen[entry.item]=true
    end
    -- B42 may omit an equipped or attached light from getActiveLightItems().
    -- Use the same mounted-item surface that lightWorks UV semantics uses.
    for _,item in ipairs(mountedPlayerLights(player)) do
        mounted[item]=true
        if not candidateSeen[item] then
            candidates[#candidates+1]=item
            candidateSeen[item]=true
        end
    end
    -- Keep inactive/attached discovery for lightWorks-owned fallback sources.
    for _,item in ipairs(lightWorks.collectPlayerLights(player)) do
        if not candidateSeen[item] then candidates[#candidates+1]=item end
    end
    for _, item in ipairs(candidates) do
        local profileItem=emitterProfileItem(item)
        -- B42's authoritative player-torch list can contain active lights whose
        -- item class does not expose isActivated()/getActivated() to Kahlua.
        -- Membership here must win over the optional item-level accessor.
        local nativeId = candidateIds[item] or nativeIds[item]
        if (nativeId~=nil or isActive(item)) and lightWorks.hasBulb(profileItem)
                and (not lightWorks.isBulbBurnedOut or not lightWorks.isBulbBurnedOut(profileItem)) then
            local bulb = lightWorks.getInstalledBulb(profileItem)
            local color = renderedColor(bulb)
            local lockChroma=bulb and ((bulb.tags and bulb.tags.UV==true)
                or (bulb.emissions and bulb.emissions.UV~=nil)) or false
            local location = attachmentLocation(player,item)
            if color or location then
                local state = ensureState(profileItem)
                seen[profileItem] = true
                -- Reuse the engine-owned ID whenever this is one of the four
                -- active player torches. A separate ID would leave the native
                -- warm-white beam underneath and wash every color toward white.
                state.active = true
                local x,y,z,ax,ay,dist,strength,cone,dot = renderGeometry(player,profileItem,state,location,item)
                local r=clamp01(color and color.r,1.0)
                local g=clamp01(color and color.g,1.0)
                local b=clamp01(color and color.b,1.0)
                -- Retain activation discovery through isActivated() after the
                -- stock emitter is suppressed; isEmittingLight() then becomes
                -- false by design.
                state.suppressed=state.suppressed or {}
                if state.suppressed[item]==nil then
                    state.suppressed[item]=callValue(item,"getLightStrength",state.strength or 0.7)
                end
                pcall(function() item:setLightStrength(0.0) end)
                local visible=LowPowerFlicker.shouldRender(profileItem)
                local patternIntensity=Patterns.evaluate(profileItem)
                if visible and patternIntensity>0 then
                    renderWorldSources(state,x,y,z,ax,ay,dist,strength*patternIntensity,cone,r,g,b,lockChroma)
                else clearSources(state) end
                local signature=string.format("%s:%.3f:%.3f:%.3f",tostring(state.bulbType),r,g,b)
                if lastReports[profileItem]~=signature then
                    lastReports[profileItem]=signature
                    print(string.format("[lightWorks] Colored world-light active item=%s emitter=%s bulb=%s rgb=%.3f,%.3f,%.3f strength=%.3f distance=%.1f",
                        tostring(item:getFullType()),tostring(profileItem:getFullType()),tostring(state.bulbType),r,g,b,strength,dist))
                end
            end
        end
    end
end

function lightWorks.refreshColoredTorches()
    if lightWorks.Config.EnableColoredLightRenderer==false then
        for _,state in pairs(states) do
            if state.active or state.suppressed then restoreState(state) end
        end
        return false
    end
    if not ArrayList or type(IsoLightSource)~="table" then return false end
    local ok, err = pcall(function()
        local seen = {}
        for playerIndex=0,3 do refreshPlayer(getSpecificPlayer(playerIndex),playerIndex,seen) end
        for item,state in pairs(states) do
            if state.active and not seen[item] then
                -- Never remove an engine-owned native ID here; the engine owns
                -- its lifecycle. Only clean up lightWorks' fallback record.
                restoreState(state)
            end
        end
    end)
    if not ok and not reportedFailure then
        reportedFailure = true
        print("[lightWorks] Colored/attached light renderer failed safely: " .. tostring(err))
    end
    return ok
end

-- Interactive technical-spike diagnostic. This deliberately performs no
-- mutation: it reports every discovery/activation gate used by the renderer so
-- a single console capture can distinguish an item-registration problem from
-- a native-torch timing problem.
function lightWorks.debugColoredTorchState(playerIndex)
    playerIndex=math.max(0,math.min(3,tonumber(playerIndex) or 0))
    local player=getSpecificPlayer(playerIndex)
    if not player then
        print("[lightWorks][ColorProbe] no player at index="..tostring(playerIndex))
        return false
    end
    local nativeIds,activeItems=nativeIdsByItem(player,playerIndex)
    print(string.format("[lightWorks][ColorProbe] player=%d activeItems=%d renderer=IsoLightSource",
        playerIndex,#activeItems))
    local seen={}
    local function report(item,origin)
        if not item or seen[item] then return end
        seen[item]=true
        local fullType=callValue(item,"getFullType","?")
        local profileItem=emitterProfileItem(item)
        local emitterType=callValue(profileItem,"getFullType","?")
        local bulbType=lightWorks.getInstalledBulbType(profileItem)
        local bulb=bulbType and lightWorks.getBulbProfile(bulbType) or nil
        local color=renderedColor(bulb)
        print(string.format("[lightWorks][ColorProbe] origin=%s item=%s emitter=%s active=%s emitting=%s registered=%s bulb=%s rgb=%s nativeId=%s attached=%s",
            tostring(origin),tostring(fullType),tostring(emitterType),tostring(callValue(item,"isActivated","n/a")),
            tostring(callValue(item,"isEmittingLight","n/a")),tostring(lightWorks.isRegisteredLight(profileItem)),
            tostring(bulbType),color and string.format("%.3f,%.3f,%.3f",color.r or 0,color.g or 0,color.b or 0) or "none",
            tostring(nativeIds[item]),tostring(attachmentLocation(player,item))))
    end
    for _,entry in ipairs(activeItems) do report(entry.item,"active-list") end
    report(callValue(player,"getPrimaryHandItem",nil),"primary")
    report(callValue(player,"getSecondaryHandItem",nil),"secondary")
    for _,item in ipairs(mountedPlayerLights(player)) do report(item,"mounted") end
    for _,item in ipairs(lightWorks.collectPlayerLights(player)) do report(item,"catalog") end
    return true
end

function LWColorProbe(playerIndex) return lightWorks.debugColoredTorchState(playerIndex) end

local function restorePlayerProfiles(player)
    if not player then return end
    for _, item in ipairs(lightWorks.collectPlayerLights(player)) do lightWorks.applyVisibleProfile(item) end
end

if Events and Events.OnRenderTick then Events.OnRenderTick.Add(lightWorks.refreshColoredTorches) end
if Events and Events.OnTick then Events.OnTick.Add(lightWorks.refreshColoredTorches) end
-- This is the latest generally available client event in the frame. Keeping
-- the same idempotent rewrite here counters LightingJNI's asynchronous
-- checkLights pass when it finishes after OnRenderTick.
if Events and Events.OnPostUIDraw then Events.OnPostUIDraw.Add(lightWorks.refreshColoredTorches) end
if Events and Events.OnGameStart then
    Events.OnGameStart.Add(function()
        for playerIndex=0,3 do restorePlayerProfiles(getSpecificPlayer(playerIndex)) end
    end)
end
if Events and Events.OnCreatePlayer then
    Events.OnCreatePlayer.Add(function(playerIndex,player)
        restorePlayerProfiles(player or getSpecificPlayer(playerIndex))
    end)
end

return lightWorks
