-- UV obstruction facts, independent of client light rendering. Caller supplies
-- glass transmission policy; visible-light clearance is not UV transparency.
local Occlusion={MAX_STEPS=128}
local function finite(v) return type(v)=="number" and v==v and math.abs(v)<math.huge end

function Occlusion.trace(cell,source,target,policy)
    if not cell or type(source)~="table" or type(target)~="table" then return nil,"invalid ray" end
    for _,p in ipairs({source,target}) do
        if not finite(p.x) or not finite(p.y) or not finite(p.z) then return nil,"invalid coordinates" end
    end
    local z=math.floor(source.z)
    if z~=math.floor(target.z) then return 0,"different floor" end
    local x,y=math.floor(source.x),math.floor(source.y)
    local endX,endY=math.floor(target.x),math.floor(target.y)
    if math.abs(endX-x)+math.abs(endY-y)>Occlusion.MAX_STEPS then return nil,"ray budget exceeded" end
    local dx,dy=target.x-source.x,target.y-source.y
    local sx=dx>0 and 1 or dx<0 and -1 or 0
    local sy=dy>0 and 1 or dy<0 and -1 or 0
    local stepX=sx==0 and math.huge or 1/math.abs(dx)
    local stepY=sy==0 and math.huge or 1/math.abs(dy)
    local nextX=sx==0 and math.huge or ((sx>0 and x+1 or x)-source.x)/dx
    local nextY=sy==0 and math.huge or ((sy>0 and y+1 or y)-source.y)/dy
    local ok,value,reason=pcall(function()
        local current=cell:getGridSquare(x,y,z)
        if not current then return nil,"unloaded source square" end
        local transmission=1
        for _=1,Occlusion.MAX_STEPS do
            if x==endX and y==endY then return transmission,"clear" end
            local ox,oy=0,0
            if nextX<nextY then ox=sx; nextX=nextX+stepX
            elseif nextY<nextX then oy=sy; nextY=nextY+stepY
            else ox,oy=sx,sy; nextX,nextY=nextX+stepX,nextY+stepY end
            local square=cell:getGridSquare(x+ox,y+oy,z)
            if not square then return nil,"unloaded ray square" end
            -- specialDiag=true asks vanilla to check both diagonal boundaries;
            -- ignoreDoors=false keeps closed doors/curtains/barricades relevant.
            local result=tostring(current:testVisionAdjacent(ox,oy,0,true,false))
            if result=="Blocked" or result=="ClearThroughClosedDoor" then return 0,result end
            if result=="ClearThroughWindow" then
                local t=policy and policy.windowTransmission
                if not finite(t) or t<0 or t>1 then return nil,"window UV policy required" end
                transmission=transmission*t
                if transmission==0 then return 0,"window" end
            elseif result~="Clear" and result~="ClearThroughOpenDoor" then
                return nil,"unknown native vision result: "..result
            end
            x,y,current=x+ox,y+oy,square
        end
        if x==endX and y==endY then return transmission,"clear" end
        return nil,"ray budget exceeded"
    end)
    if not ok then return nil,"native vision unavailable: "..tostring(value) end
    return value,reason
end
return Occlusion
