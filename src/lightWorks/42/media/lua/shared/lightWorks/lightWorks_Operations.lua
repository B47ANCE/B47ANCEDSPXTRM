-- Opaque intent IDs are not authorization. Existing server ownership checks and
-- bounded persisted replay histories remain the trust boundary.
local Operations={}
function Operations.new(kind)
    if type(kind)~="string" or #kind>16 or not kind:match("^[A-Z]+$") then return nil,"invalid operation kind" end
    local generate=rawget(_G,"getRandomUUID")
    if type(generate)~="function" then return nil,"UUID generator unavailable" end
    local ok,id=pcall(generate)
    if not ok or type(id)~="string" or #id~=36 or not id:match("^[%x%-]+$") then
        return nil,"UUID generation failed"
    end
    return "LW-"..kind.."-"..id
end
return Operations
