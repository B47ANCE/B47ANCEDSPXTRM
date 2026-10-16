local WorldPower=require "lightWorks/lightWorks_WorldPower"
local Access=require "lightWorks/lightWorks_ItemAccess"

local function finiteInteger(value)return type(value)=="number"and value==value and math.abs(value)<math.huge and value==math.floor(value)end
local function locate(args)
    if not finiteInteger(args.x)or not finiteInteger(args.y)or not finiteInteger(args.z)or not finiteInteger(args.itemId)then return nil end
    local cell=type(getCell)=="function"and getCell()or nil;local _,square=Access.call(cell,"getGridSquare",args.x,args.y,args.z)
    local _,objects=Access.call(square,"getWorldObjects");local _,count=Access.call(objects,"size")
    local found
    for index=0,math.min(128,math.max(0,tonumber(count)or 0))-1 do
        local got,backing=Access.call(objects,"get",index);local itemOk,item=false,nil
        if got then itemOk,item=Access.call(backing,"getItem")end
        if itemOk and item then local idOk,id=Access.call(item,"getID");if idOk and id==args.itemId then if found then return nil end;found={backing=backing,item=item}end end
    end
    return found,square
end
local function nearby(player,args)
    local _,px=Access.call(player,"getX");local _,py=Access.call(player,"getY");local _,pz=Access.call(player,"getZ")
    px,py,pz=tonumber(px),tonumber(py),tonumber(pz)
    return px and py and pz and math.floor(pz)==args.z and (px-args.x)^2+(py-args.y)^2<=9
end
local ORIENTATION={N=true,E=true,S=true,W=true}
local function setOrientation(resolved,orientation)
    orientation=type(orientation)=="string"and string.upper(orientation)or nil
    if not ORIENTATION[orientation]then return false end
    local data=Access.modData(resolved.item);if type(data)~="table"then return false end
    data.lightWorksWorldEmitter=type(data.lightWorksWorldEmitter)=="table"and data.lightWorksWorldEmitter or{schemaVersion=1}
    data.lightWorksWorldEmitter.orientation=orientation
    Access.call(resolved.item,"transmitModData")
    WorldPower.prepareBacking(resolved.backing,resolved.item)
    return true,orientation
end
local function onCommand(module,command,player,args)
    if module~="lightWorks"or(command~="setWorldEmitterActive"and command~="setWorldEmitterOrientation")or type(args)~="table"or not player then return end
    if not finiteInteger(args.x)or not finiteInteger(args.y)or not finiteInteger(args.z)or not finiteInteger(args.itemId)
        or type(args.operationId)~="string"or args.operationId==""or #args.operationId>128
        or not nearby(player,args)then return end
    local resolved=locate(args);if not resolved or not lightWorks.supportsWorldEmission(resolved.item)then return end
    if command=="setWorldEmitterOrientation"then
        local profile=lightWorks.getLightProfile(resolved.item)
        if not profile or not profile.emitter or profile.emitter.cone~=true then return end
        local changed,orientation=setOrientation(resolved,args.orientation);if not changed then return end
        if type(sendServerCommand)=="function"then
            pcall(sendServerCommand,"lightWorks","worldEmitterOrientation",{x=args.x,y=args.y,z=args.z,
                itemId=args.itemId,orientation=orientation,operationId=args.operationId})
        end
        return
    end
    if type(args.active)~="boolean"then return end
    local ok,state=WorldPower.setActive(resolved.item,args.active,args.operationId);if not ok then return end
    WorldPower.prepareBacking(resolved.backing,resolved.item)
    if type(sendServerCommand)=="function"then
        pcall(sendServerCommand,"lightWorks","worldEmitterState",{x=args.x,y=args.y,z=args.z,itemId=args.itemId,
            active=state.active,operationId=state.operationId})
    end
end
if Events and Events.OnClientCommand then Events.OnClientCommand.Add(onCommand)end
return{locate=locate,onCommand=onCommand,setOrientation=setOrientation}
