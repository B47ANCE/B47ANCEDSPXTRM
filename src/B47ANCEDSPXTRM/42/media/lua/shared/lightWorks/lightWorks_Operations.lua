-- Opaque intent IDs are not authorization. Existing server ownership checks and
-- bounded persisted replay histories remain the trust boundary.
local Operations={}
function Operations.validHistory(history)
    if type(history)~="table" then return false end
    local count,maximum,seen=0,0,{}
    for key,id in pairs(history) do
        count=count+1
        if count>32 or type(key)~="number" or key<1 or key>32 or key~=math.floor(key)
            or type(id)~="string" or #id==0 or #id>128 or seen[id] then return false end
        maximum=math.max(maximum,key);seen[id]=true
    end
    return maximum==count
end
function Operations.new(kind)
    if type(kind)~="string" or #kind>16 or not kind:match("^[A-Z]+$") then return nil,"invalid operation kind" end
    local generate=rawget(_G,"getRandomUUID")
    if type(generate)~="function" then return nil,"UUID generator unavailable" end
    local ok,id=pcall(generate)
    if not ok or type(id)~="string" or #id~=36 or not id:match("^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$") then
        return nil,"UUID generation failed"
    end
    return "LW-"..kind.."-"..id
end
return Operations
