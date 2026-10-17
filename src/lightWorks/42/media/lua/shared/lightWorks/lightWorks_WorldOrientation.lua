local Operations=require "lightWorks/lightWorks_Operations"
local API=require "lightWorks/lightWorks_API"
local Access=require "lightWorks/lightWorks_ItemAccess"
local Direction=require "lightWorks/lightWorks_Direction"
local Notices=require "lightWorks/lightWorks_Notifications"
local Orientation={}
function Orientation.set(item,value,operationId)
    if type(isClient)=="function" and isClient()==true
        and not(type(isServer)=="function" and isServer()==true) then return false,"non-authority" end
    value=Direction.normalize(value)
    if value==nil or type(operationId)~="string" or #operationId==0 or #operationId>128 then return false,"invalid orientation request" end
    local profile=API.getLightProfile(item)
    if not API.supportsWorldEmission(item) or not profile or not profile.emitter or profile.emitter.cone~=true then return false,"directional light required" end
    local data=Access.modData(item);if not data then return false,"ModData unavailable" end
    local old=data.lightWorksWorldEmitter
    if old~=nil and (type(old)~="table" or old.schemaVersion~=1
        or (old.processedOperations~=nil and not Operations.validHistory(old.processedOperations))) then return false,"unsupported world state" end
    local history=old and old.processedOperations or {}
    for _,id in ipairs(history) do if id==operationId then return false,"duplicate operation" end end
    local state=old or {schemaVersion=1}
    state.processedOperations=history
    state.orientation=value;history[#history+1]=operationId
    while #history>32 do table.remove(history,1) end
    data.lightWorksWorldEmitter=state
    Access.call(item,"transmitModData")
    Notices.publish("orientation","selected",Notices.item(item),{orientation=value,operationId=operationId})
    return true,value
end
return Orientation
