-- Shared bounded enumeration. Remote players are presentation candidates only;
-- callers remain responsible for authority checks before gameplay mutation.
local Players={MAX_PLAYERS=256,RENDER_RADIUS=32}
local function read(object,method,arg)
    if not object then return nil end
    local ok,value=pcall(function() return object[method](object,arg) end)
    return ok and value or nil
end
function Players.collect(nearLocal)
    local result,seen,locals={},{},{}
    local function add(player)
        if player and not seen[player] and #result<Players.MAX_PLAYERS then
            seen[player]=true;result[#result+1]=player
        end
    end
    if type(getSpecificPlayer)=="function" and (nearLocal or not(type(isServer)=="function" and isServer()==true)) then
        for index=0,3 do
            local ok,player=pcall(getSpecificPlayer,index)
            if ok and player then locals[#locals+1]=player;add(player) end
        end
    end
    if type(getOnlinePlayers)=="function" then
        local ok,list=pcall(getOnlinePlayers)
        local count=ok and tonumber(read(list,"size")) or 0
        count=count and count==count and math.min(Players.MAX_PLAYERS,math.max(0,count)) or 0
        for index=0,count-1 do
            local player=read(list,"get",index)
            if not nearLocal then add(player)
            elseif player then
                local x,y,z=read(player,"getX"),read(player,"getY"),read(player,"getZ")
                for _,viewer in ipairs(locals) do
                    local vx,vy,vz=read(viewer,"getX"),read(viewer,"getY"),read(viewer,"getZ")
                    if x and y and z and vx and vy and vz and math.floor(z)==math.floor(vz)
                        and (x-vx)^2+(y-vy)^2<=Players.RENDER_RADIUS^2 then add(player);break end
                end
            end
        end
    end
    return result
end
return Players
