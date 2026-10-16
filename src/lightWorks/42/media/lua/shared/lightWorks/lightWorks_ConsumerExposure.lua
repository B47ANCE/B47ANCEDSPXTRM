local API=require "lightWorks/lightWorks_API"
local Access=require "lightWorks/lightWorks_ItemAccess"
local Sources=require "lightWorks/lightWorks_EmissionSources"
local UV=require "lightWorks/lightWorks_UV"
local Occlusion=require "lightWorks/lightWorks_UVOcclusion"
local Exposure={RADIUS=16,MAX_SOURCES=64}
local function finite(v) return type(v)=="number" and v==v and math.abs(v)<math.huge end
function Exposure.point(x,y,z)
    if not finite(x) or not finite(y) or not finite(z) then return nil end
    -- Native grid coordinates are integer arguments; leave room for the scan
    -- radius and reject values that also make numeric-for increments stall.
    if math.abs(x)>2147483615 or math.abs(y)>2147483615 or math.abs(z)>2147483615 then return nil end
    return {x=x,y=y,z=z,getX=function()return x end,getY=function()return y end,getZ=function()return z end,
        getSquare=function()
            local cell=type(getCell)=="function" and getCell()
            local ok,square=Access.call(cell,"getGridSquare",math.floor(x),math.floor(y),math.floor(z))
            return ok and square or nil
        end}
end
function Exposure.position(object)
    local _,world=Access.call(object,"getWorldItem")
    object=world or object
    local _,x=Access.call(object,"getX");local _,y=Access.call(object,"getY");local _,z=Access.call(object,"getZ")
    return Exposure.point(x,y,z)
end
function Exposure.sample(point)
    if not point then return nil,"world position unavailable" end
    local cell=type(getCell)=="function" and getCell()
    if not cell then return nil,"world cell unavailable" end
    local sources,scan=Sources.collectWorld(point,Exposure.RADIUS,Exposure.MAX_SOURCES)
    local complete=not scan or scan.complete==true
    local emitters,visible={},0
    for _,source in ipairs(sources) do
        local origin=Exposure.point(source.x,source.y,source.z)
        if not origin then complete=false
        else
            if source.channels and source.channels.UV then
                emitters[#emitters+1]={owner=origin,intensity=source.uvIntensity,range=source.uvRange,
                    spectrum=source.spectrum,directional=source.directional,directionX=source.directionX,directionY=source.directionY}
            end
            local range,intensity=source.visibleRange or source.range,source.visibleIntensity or source.intensity
            if not finite(range) or range<=0 or not finite(intensity) or intensity<0 then complete=false
            elseif math.floor(source.z)==math.floor(point.z) then
                local dx,dy=point.x-source.x,point.y-source.y
                local distance=math.sqrt(dx*dx+dy*dy)
                local inCone=true
                if source.directional and distance>.0001 then
                    local fx,fy=source.directionX,source.directionY
                    if not finite(fx) or not finite(fy) or fx*fx+fy*fy<.000001 then complete=false;inCone=false
                    else
                        local length=math.sqrt(fx*fx+fy*fy)
                        inCone=(dx*fx+dy*fy)/(distance*length)>=(UV.CONE_DOT_THRESHOLD or .45)
                    end
                end
                if distance<=range and inCone and intensity>0 then
                    local transmission=Occlusion.trace(cell,origin,point,{windowTransmission=1})
                    if transmission==nil then complete=false
                    else visible=visible+intensity*math.max(.20,1-distance/range*.65)*transmission end
                end
            end
        end
    end
    -- UV treatment uses conservative zero transmission through windows. This is
    -- a consumer safety policy, not a physical claim about arbitrary glass.
    local artificial=UV.getOccludedArtificialExposure(point,emitters,{cell=cell,windowTransmission=0})
    artificial.uv.complete=artificial.uv.complete and complete
    local sunlight=UV.getSunlightExposure(point)
    local sunlightKnown=sunlight and sunlight.uv and sunlight.uv.complete==true
    local natural=sunlightKnown and sunlight.visible or nil
    local total=natural and natural+visible or nil
    if not finite(visible) or (total~=nil and not finite(total)) then return nil,"optical arithmetic overflow" end
    return {schemaVersion=1,scope="loaded world/fixture sources",radius=Exposure.RADIUS,
        complete=complete and sunlightKnown and artificial.uv.complete,artificialComplete=artificial.uv.complete,
        naturalVisible=natural,artificialVisible=visible,totalVisible=total,uv=artificial.uv,
        sourceCount=#sources,scan=scan}
end
API.ConsumerExposure=Exposure
return Exposure
