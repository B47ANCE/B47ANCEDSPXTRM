-- Explicit feasibility prototype. Never install render hooks in normal play.
if type(isDebugEnabled)~="function" or isDebugEnabled()~=true then return {} end

require "lightWorks/lightWorks_API"

-- Render-only feasibility spike for native blood decals. This intentionally
-- ignores emitter geometry: first prove that B42's FBO pass accepts a second,
-- colored native-splat submission, then connect it to the UV exposure API.
local lightWorks = lightWorks
local Prototype = {
    active = false,
    mode = "fluorescence",
    radius = 12,
    lastDetected = 0,
    lastRendered = 0,
    lastMissingSprite = 0,
    lastError = nil,
}
lightWorks.UVReactionPrototype = Prototype

local colors = {
    -- Untreated whole blood is primarily an absorption/contrast target.
    absorption = {r=0.055, g=0.008, b=0.012, a=0.92},
    -- Intentionally obvious diagnostic color, not the production blood model.
    fluorescence = {r=0.12, g=0.55, b=1.00, a=0.88},
}

local function log(message)
    print("[lightWorks][UVReactionTest] " .. tostring(message))
end

local function player0()
    return (getSpecificPlayer and getSpecificPlayer(0)) or (getPlayer and getPlayer()) or nil
end

local function uniqueNearbyChunks(player, radius)
    local cell = getCell and getCell() or nil
    if not player or not cell then return {} end
    local chunks, seen = {}, {}
    local minX, maxX = math.floor(player:getX()-radius), math.ceil(player:getX()+radius)
    local minY, maxY = math.floor(player:getY()-radius), math.ceil(player:getY()+radius)
    for x=minX,maxX,8 do
        for y=minY,maxY,8 do
            local ok, chunk = pcall(function() return cell:getChunkForGridSquare(x,y,player:getZ()) end)
            if ok and chunk and not seen[chunk] then seen[chunk]=true; chunks[#chunks+1]=chunk end
        end
    end
    -- Include the far boundary when it belongs to a chunk missed by the step.
    for _,point in ipairs({{maxX,minY},{minX,maxY},{maxX,maxY}}) do
        local ok, chunk = pcall(function() return cell:getChunkForGridSquare(point[1],point[2],player:getZ()) end)
        if ok and chunk and not seen[chunk] then seen[chunk]=true; chunks[#chunks+1]=chunk end
    end
    return chunks
end

local function floorSprite(splat)
    if not IsoFloorBloodSplat or not splat then return nil end
    local okName, textureName = pcall(function()
        return IsoFloorBloodSplat.FLOOR_BLOOD_TYPES[splat.type]
    end)
    if not okName or not textureName then return nil end
    local okSprite, sprite = pcall(function()
        return IsoFloorBloodSplat.spriteMap:get(textureName)
    end)
    return okSprite and sprite or nil
end

local function eachQueue(queue, callback)
    if not queue then return end
    local okSize, size = pcall(function() return queue:size() end)
    if not okSize then return end
    for index=0,size-1 do
        local okItem, item = pcall(function() return queue:get(index) end)
        if okItem and item then callback(item) end
    end
end

local function renderLayer(level)
    if not Prototype.active then return end
    local player = player0()
    if not player or math.floor(player:getZ()) ~= tonumber(level) then return end
    local selected = colors[Prototype.mode] or colors.fluorescence
    local color = ColorInfo.new(selected.r,selected.g,selected.b,selected.a)
    local radius2 = Prototype.radius*Prototype.radius
    local px,py = player:getX(),player:getY()
    local detected,rendered,missing = 0,0,0
    local ok,err = pcall(function()
        for _,chunk in ipairs(uniqueNearbyChunks(player,Prototype.radius)) do
            local function submit(splat)
                local x = chunk.wx*8+splat.x
                local y = chunk.wy*8+splat.y
                local z = splat.z
                local dx,dy=x-px,y-py
                if math.floor(z)==tonumber(level) and dx*dx+dy*dy<=radius2 then
                    detected=detected+1
                    local sprite=floorSprite(splat)
                    if sprite then sprite:renderBloodSplat(x,y,z,color); rendered=rendered+1
                    else missing=missing+1 end
                end
            end
            eachQueue(chunk.floorBloodSplats,submit)
            local fading=chunk.floorBloodSplatsFade
            if fading then
                local size=fading:size()
                for index=0,size-1 do submit(fading:get(index)) end
            end
        end
    end)
    Prototype.lastDetected,Prototype.lastRendered,Prototype.lastMissingSprite=detected,rendered,missing
    Prototype.lastError=ok and nil or tostring(err)
    if not ok then Prototype.active=false; log("disabled safely after render error: "..tostring(err)) end
end

function LWUVBloodTest(mode)
    mode = mode and string.lower(tostring(mode)) or nil
    if mode=="off" then Prototype.active=false; log("OFF"); return true end
    if mode=="status" then
        log(string.format("active=%s mode=%s radius=%d detected=%d rendered=%d missingSprite=%d error=%s",
            tostring(Prototype.active),Prototype.mode,Prototype.radius,Prototype.lastDetected,
            Prototype.lastRendered,Prototype.lastMissingSprite,tostring(Prototype.lastError)))
        return Prototype
    end
    if mode and not colors[mode] then
        log("unknown mode; use fluorescence, absorption, status, or off")
        return false
    end
    Prototype.mode=mode or Prototype.mode
    Prototype.active=true
    log("ON mode="..Prototype.mode.."; use LWUVBloodTest('status') after inspecting")
    return true
end

function LWUVBloodTestRadius(radius)
    Prototype.radius=math.max(2,math.min(30,math.floor(tonumber(radius) or 12)))
    log("radius="..Prototype.radius)
    return Prototype.radius
end

function LWUVBloodTestPlace(count)
    if type(isClient)=="function" and isClient()==true then log("sample placement is SP-only"); return false end
    local player=player0(); local square=player and player:getSquare() or nil
    if not square or not addBloodSplat then log("cannot place sample here"); return false end
    count=math.max(1,math.min(40,math.floor(tonumber(count) or 12)))
    addBloodSplat(square,count)
    log("placed "..count.." persistent vanilla blood splats at the player square")
    return true
end

if Events and Events.OnPostFloorLayerDraw then Events.OnPostFloorLayerDraw.Add(renderLayer) end
log("Ready: LWUVBloodTest('fluorescence'|'absorption'|'status'|'off'), LWUVBloodTestPlace(count)")

return Prototype
