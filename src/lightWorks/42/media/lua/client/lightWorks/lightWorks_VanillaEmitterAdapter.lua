local Direction=require "lightWorks/lightWorks_Direction"
local Occlusion=require "lightWorks/lightWorks_UVOcclusion"
local Adapter={capabilities=nil}

local function call(object,method,...)
    if not object then return false,nil end
    local ok,fn=pcall(function() return object[method] end)
    if not ok or type(fn)~="function" then return false,nil end
    return pcall(fn,object,...)
end

function Adapter.probe()
    if Adapter.capabilities then return Adapter.capabilities end
    Adapter.capabilities={
        create=type(IsoLightSource)=="table" and type(IsoLightSource.new)=="function",
        add=type(getCell)=="function",
        remove=type(getCell)=="function",
    }
    return Adapter.capabilities
end

function Adapter.position(backing)
    local ok,square=call(backing,"getSquare")
    if not ok or not square then return nil end
    local _,x=call(backing,"getX");local _,y=call(backing,"getY");local _,z=call(backing,"getZ")
    if x==nil then _,x=call(square,"getX") end
    if y==nil then _,y=call(square,"getY") end
    if z==nil then _,z=call(square,"getZ") end
    return tonumber(x),tonumber(y),tonumber(z)
end

function Adapter.exists(backing)
    if not backing then return false end
    local healthOk,health=call(backing,"getThumpCondition")
    if healthOk and type(health)=="number" and health<=0 then return false end
    local ok,value=call(backing,"isExistInTheWorld")
    if ok then return value==true end
    local squareOk,square=call(backing,"getSquare")
    return squareOk and square~=nil
end

function Adapter.setAttackable(backing,value)
    if value==true then
        local healthOk,condition=call(backing,"getThumpCondition")
        if healthOk and tonumber(condition)and tonumber(condition)<=0 then
            call(backing,"setMovedThumpable",false);return false,"world backing is already destroyed"
        end
    end
    local ok=call(backing,"setMovedThumpable",value==true)
    if not ok then return false,"world backing has no verified thumpable toggle"end
    return true
end

function Adapter.create(x,y,z,color,radius)
    local caps=Adapter.probe();if not caps.create or not caps.add then return nil,"IsoLightSource unavailable" end
    local ok,source=pcall(IsoLightSource.new,math.floor(x),math.floor(y),math.floor(z),
        color.r,color.g,color.b,math.max(1,math.floor(radius+0.5)))
    if not ok or not source then return nil,"IsoLightSource creation failed" end
    local cell=getCell();local added=cell and pcall(function() cell:addLamppost(source) end)
    if not added then return nil,"IsoCell light registration failed" end
    return source
end

function Adapter.remove(source)
    if not source then return true end
    local cell=type(getCell)=="function" and getCell() or nil
    return cell and pcall(function() cell:removeLamppost(source) end) or false
end

function Adapter.createDirectional(x,y,z,color,profile,phase,orientation)
    local dx,dy=Direction.vector(orientation)
    if not dx then return nil,"valid orientation required"end
    profile=type(profile)=="table"and profile or{}
    local distance=math.max(1,tonumber(profile.radius)or 6)
    local nodes=math.max(2,math.min(8,math.floor(tonumber(profile.nodes)or 4)))
    local width=math.max(0.1,tonumber(profile.width)or 0.7)
    local falloff=math.max(0.1,math.min(1,tonumber(profile.falloff)or 0.72))
    phase=math.max(0.01,math.min(1,tonumber(phase)or 1))
    local sources,cell={},type(getCell)=="function"and getCell()or nil
    if not cell then return nil,"IsoCell unavailable"end
    local prior=cell:getGridSquare(math.floor(x),math.floor(y),math.floor(z))
    for index=0,nodes-1 do
        local fraction=index/math.max(1,nodes-1)
        local travel=distance*fraction
        local sx,sy=math.floor(x+dx*travel),math.floor(y+dy*travel)
        local square=cell:getGridSquare(sx,sy,math.floor(z));if not square then break end
        local transmission=Occlusion.trace(cell,{x=x,y=y,z=z},{x=sx+.5,y=sy+.5,z=z},{windowTransmission=1})
        if transmission~=1 then break end
        local localStrength=phase*(falloff^index)
        local radius=math.max(1,(distance/nodes)*(0.8+width)*math.sqrt(localStrength))
        local source,reason=Adapter.create(sx,sy,z,color,radius)
        if not source then
            for _,created in ipairs(sources)do Adapter.remove(created)end
            return nil,reason
        end
        sources[#sources+1]=source;prior=square
    end
    if #sources==0 then return nil,"directional path unavailable"end
    return sources
end

function Adapter.removeAll(sources)
    local removed=true
    for _,source in ipairs(type(sources)=="table"and sources or{})do
        if not Adapter.remove(source)then removed=false end
    end
    return removed
end

return Adapter
