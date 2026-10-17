-- Independent conversion from the identifier/field contract in EXT-35.
-- The legacy record is retained byte-for-byte; no legacy implementation loads.
local API=require "lightWorks/lightWorks_API"
local Access=require "lightWorks/lightWorks_ItemAccess"
local Notices=require "lightWorks/lightWorks_Notifications"
local Migration={SCHEMA_VERSION=1,aliases={},MAX_ALIASES=64}
local KEY="lightWorksLegacyMigration"
local function finite(v) return type(v)=="number" and v==v and math.abs(v)<math.huge end
local function authority()
    return not(type(isClient)=="function" and isClient()==true
        and not(type(isServer)=="function" and isServer()==true))
end
local function disabledLegacy()
    if rawget(_G,"Bulbworks")~=nil then return false end
    if type(getActivatedMods)~="function" then return nil end
    local ok,list=pcall(getActivatedMods);local read,count=Access.call(list,"size")
    if not ok or not read or not finite(count) or count<0 or count>4096 then return nil end
    for index=0,count-1 do
        local got,id=Access.call(list,"get",index)
        if not got then return nil end
        if id=="Bulbworks" or id=="\\Bulbworks" then return false end
    end
    return true
end
function Migration.registerAlias(oldType,newType,owner)
    assert(type(oldType)=="string" and #oldType>0 and #oldType<=128,"legacy bulb ID required")
    assert(type(newType)=="string" and API.getBulbProfile(newType),"registered replacement bulb required")
    assert(type(owner)=="string" and #owner>0 and #owner<=128,"explicit alias owner required")
    assert(not Migration.aliases[oldType],"duplicate legacy bulb alias")
    local count=0;for _ in pairs(Migration.aliases) do count=count+1 end
    assert(count<Migration.MAX_ALIASES,"legacy alias limit")
    Migration.aliases[oldType]={item=newType,owner=owner}
end
local function bulb(value)
    if value==nil then return nil,true end
    if type(value)~="string" or #value>128 then return nil,false end
    if API.getBulbProfile(value) then return value,true end
    local alias=Migration.aliases[value]
    return alias and alias.item,alias~=nil
end
local booleans={hasExplicitBulbState=true,burnedOut=true,baseVisibleCaptured=true,baseTorchCone=true}
local numbers={burnMinutes=true,baseLightStrength=true,baseLightDistance=true,baseTorchDot=true,
    baseColorRed=true,baseColorGreen=true,baseColorBlue=true}
local function convert(old)
    if type(old)~="table" then return nil,"malformed legacy state" end
    local result,count={},0
    for key,value in pairs(old) do
        count=count+1;if count>32 then return nil,"legacy field budget exceeded" end
        if booleans[key] then
            if type(value)~="boolean" then return nil,"invalid legacy boolean" end
        elseif numbers[key] then
            if not finite(value) then return nil,"invalid legacy number" end
            if key=="baseTorchDot" then
                if value< -1 or value>1 then return nil,"unknown native dot range" end
            elseif value<0 or (key:find("baseColor",1,true) and value>1) then return nil,"legacy number out of bounds" end
        elseif key=="installedBulb" or key=="lastBurnedBulbType" then
            local mapped,ok=bulb(value);if not ok then return nil,"unresolved legacy bulb identity" end
            value=mapped
        elseif key=="spawnBulbContext" then
            if type(value)~="string" or #value>128 then return nil,"invalid legacy context" end
        else return nil,"unknown legacy field" end
        result[key]=value
    end
    if result.installedBulb and result.hasExplicitBulbState~=true then return nil,"contradictory bulb state" end
    if result.burnedOut==true and (result.installedBulb~=nil or result.hasExplicitBulbState~=true
        or not result.lastBurnedBulbType) then return nil,"contradictory burnout state" end
    local colors=0
    for _,key in ipairs({"baseColorRed","baseColorGreen","baseColorBlue"}) do if result[key]~=nil then colors=colors+1 end end
    if colors~=0 and colors~=3 then return nil,"partial legacy color baseline" end
    return result
end
function Migration.process(item,player,parentWeapon)
    if not authority() then return false,"non-authority" end
    local data=Access.modData(item)
    if type(data)~="table" or data.Bulbworks==nil then return true,"no legacy state" end
    if not API.isRegisteredLight(item) then return false,"unregistered legacy light" end
    local receipt=data[KEY]
    if receipt~=nil and (type(receipt)~="table" or receipt.schemaVersion~=1) then return false,"unknown migration receipt" end
    if receipt and receipt.status=="migrated" then return true,"already migrated" end
    local idOk,id=Access.call(item,"getID")
    if not idOk or not finite(id) or id~=math.floor(id) then return false,"stable item identity unavailable" end
    local off=disabledLegacy()
    local reason=off~=true and (off==false and "legacy runtime is active" or "legacy runtime status unknown") or nil
    local current=data[API.MODDATA_KEY]
    if current~=nil then
        if type(current)~="table" then reason="conflicting current state"
        else for _ in pairs(current) do reason="conflicting current state";break end end
    end
    local converted
    if not reason then converted,reason=convert(data.Bulbworks) end
    if not reason and converted.installedBulb and not API.isCompatible(item,converted.installedBulb) then reason="incompatible legacy bulb" end
    local status=reason and "quarantined" or "migrated"
    if receipt and receipt.status==status and receipt.reason==reason then return false,reason end
    if not reason then data[API.MODDATA_KEY]=converted end
    data[KEY]={schemaVersion=1,status=status,reason=reason,itemId=id}
    -- Existing native item/weapon transport remains the serialization owner.
    if player then Access.syncServiceState(player,item,parentWeapon)
    else Access.call(item,"transmitModData");Access.call(item,"syncItemFields") end
    Notices.publish("migration",status,Notices.item(item),reason and {reason=reason} or {})
    return not reason,reason or "migrated"
end
function Migration.isBlocked(item)
    local data=Access.modData(item)
    if type(data)~="table" or data.Bulbworks==nil then return false end
    local receipt=data[KEY]
    return type(receipt)~="table" or receipt.schemaVersion~=1 or receipt.status~="migrated"
end
API.LegacyMigration=Migration
return Migration
