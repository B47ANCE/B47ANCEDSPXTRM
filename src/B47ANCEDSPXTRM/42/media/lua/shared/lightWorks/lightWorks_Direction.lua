local Direction={}
local cardinal={N={0,-1},NE={1,-1},E={1,0},SE={1,1},S={0,1},SW={-1,1},W={-1,0},NW={-1,-1}}
function Direction.normalize(value)
    if type(value)=="string" then
        value=string.upper(value)
        return cardinal[value] and value or nil
    end
    if type(value)=="number" and value==value and value>=0 and value<360 then return value end
end
-- Degrees clockwise from north; existing cardinal strings remain valid saves.
function Direction.vector(value)
    value=Direction.normalize(value)
    if value==nil then return nil end
    local c=cardinal[value]
    if c then local length=math.sqrt(c[1]^2+c[2]^2);return c[1]/length,c[2]/length end
    local angle=math.rad(value);return math.sin(angle),-math.cos(angle)
end
function Direction.fromVector(x,y)
    if type(x)~="number" or type(y)~="number" or x~=x or y~=y
        or math.abs(x)==math.huge or math.abs(y)==math.huge or x*x+y*y<.000001 then return nil end
    local a
    if math.atan2 then a=math.atan2(x,-y)
    elseif y==0 then a=x>0 and math.pi/2 or -math.pi/2
    else a=math.atan(x/-y);if y>0 then a=a+(x>=0 and math.pi or -math.pi) end end
    return math.deg(a)%360
end
return Direction
