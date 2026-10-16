local Direction=require "lightWorks/lightWorks_Direction"
local Orientation=require "lightWorks/lightWorks_WorldOrientation"
require "TimedActions/ISBaseTimedAction"
require "luautils"
local Access=require "lightWorks/lightWorks_ItemAccess"
local WorldPower=require "lightWorks/lightWorks_WorldPower"
local Manager=require "lightWorks/lightWorks_WorldEmitterManager"
local Operations=require "lightWorks/lightWorks_Operations"

local function tr(key,fallback,...)
    local args={...}
    local function substitute(value)
        return (tostring(value):gsub("%%(%d+)",function(index)
            local replacement=args[tonumber(index)]
            return replacement==nil and "%"..index or tostring(replacement)
        end))
    end
    local get=rawget(_G,"getText")
    if type(get)~="function" then return substitute(fallback) end
    local expand=table.unpack or unpack
    local ok,value=pcall(get,key,expand(args))
    if ok and type(value)=="string" and value~="" and value~=key then return value end
    return substitute(fallback)
end

local function state(item)
    local data=Access.modData(item);local world=data and data.lightWorksWorldEmitter
    if type(world)=="table"and type(world.active)=="boolean"then return world.active end
    local ok,value=Access.call(item,"isActivated");return ok and value==true
end
local function coordinates(backing)
    local _,x=Access.call(backing,"getX");local _,y=Access.call(backing,"getY");local _,z=Access.call(backing,"getZ")
    return math.floor(tonumber(x)or-99999),math.floor(tonumber(y)or-99999),math.floor(tonumber(z)or-99999)
end
local function operation(item)
    return Operations.new("WORLD")
end

local Action=ISBaseTimedAction:derive("lightWorks_WorldEmitterToggleAction")
function Action:isValid()
    if not self.character or not self.backing or not self.item then return false end
    local itemOk,current=Access.call(self.backing,"getItem");if not itemOk or current~=self.item then return false end
    local squareOk,square=Access.call(self.backing,"getSquare");if not squareOk or not square then return false end
    local _,px=Access.call(self.character,"getX");local _,py=Access.call(self.character,"getY");local _,pz=Access.call(self.character,"getZ");local x,y,z=coordinates(self.backing)
    return tonumber(px)and tonumber(py)and tonumber(pz)and math.floor(pz)==z and (px-x)^2+(py-y)^2<=9 and lightWorks.supportsWorldEmission(self.item)
end
local OrientationAction=ISBaseTimedAction:derive("lightWorks_WorldEmitterOrientationAction")
function OrientationAction:isValid()
    if not self.character or not self.backing or not self.item or Direction.normalize(self.orientation)==nil then return false end
    local itemOk,current=Access.call(self.backing,"getItem");if not itemOk or current~=self.item then return false end
    local squareOk,square=Access.call(self.backing,"getSquare");if not squareOk or not square then return false end
    local profile=lightWorks.getLightProfile(self.item)
    if not profile or not profile.emitter or profile.emitter.cone~=true then return false end
    local _,px=Access.call(self.character,"getX");local _,py=Access.call(self.character,"getY");local _,pz=Access.call(self.character,"getZ");local x,y,z=coordinates(self.backing)
    return tonumber(px)and tonumber(py)and tonumber(pz)and math.floor(pz)==z and(px-x)^2+(py-y)^2<=9
end
function OrientationAction:perform()
    if not self:isValid()then ISBaseTimedAction.perform(self);return end
    local x,y,z=coordinates(self.backing);local _,itemId=Access.call(self.item,"getID");local op=operation(self.item)
    if not op then ISBaseTimedAction.perform(self);return end
    if type(isClient)=="function"and isClient()==true then
        if type(sendClientCommand)=="function"then pcall(sendClientCommand,self.character,"lightWorks","setWorldEmitterOrientation",
            {x=x,y=y,z=z,itemId=itemId,orientation=self.orientation,operationId=op})end
    else
        local changed,value=Orientation.set(self.item,self.orientation,op)
        if changed then Manager.ensure(self.backing,nil,value) end
    end
    ISBaseTimedAction.perform(self)
end
function OrientationAction:new(character,backing,item,orientation)
    local o=ISBaseTimedAction.new(self,character);o.character=character;o.backing=backing;o.item=item;o.orientation=orientation
    o.stopOnWalk=true;o.stopOnRun=true;o.maxTime=character and character.isTimedActionInstant and character:isTimedActionInstant()and 1 or 15
    return o
end
function Action:perform()
    if not self:isValid()then ISBaseTimedAction.perform(self);return end
    local x,y,z=coordinates(self.backing);local _,itemId=Access.call(self.item,"getID");local op=operation(self.item)
    if not op then ISBaseTimedAction.perform(self);return end
    if type(isClient)=="function"and isClient()==true then
        if type(sendClientCommand)=="function"then pcall(sendClientCommand,self.character,"lightWorks","setWorldEmitterActive",
            {x=x,y=y,z=z,itemId=itemId,active=self.active,operationId=op})end
    else
        local ok=WorldPower.setActive(self.item,self.active,op);if ok then Manager.ensure(self.backing,self.active)end
    end
    ISBaseTimedAction.perform(self)
end
function Action:new(character,backing,item,active)
    local o=ISBaseTimedAction.new(self,character);o.character=character;o.backing=backing;o.item=item;o.active=active
    o.stopOnWalk=true;o.stopOnRun=true;o.maxTime=character and character.isTimedActionInstant and character:isTimedActionInstant()and 1 or 25
    return o
end

local function findBacking(worldobjects)
    local seen={}
    local function consider(backing)
        if not backing or seen[backing]then return nil end;seen[backing]=true
        local ok,item=Access.call(backing,"getItem")
        return ok and item and lightWorks.supportsWorldEmission(item)and backing or nil
    end
    for _,object in ipairs(type(worldobjects)=="table"and worldobjects or{})do
        local direct=consider(object);if direct then return direct end
        local _,square=Access.call(object,"getSquare");local _,objects=Access.call(square,"getWorldObjects");local _,count=Access.call(objects,"size")
        for index=0,math.min(32,math.max(0,tonumber(count)or 0))-1 do local _,backing=Access.call(objects,"get",index);local found=consider(backing);if found then return found end end
    end
end
local function choose(playerNum,backing,item,active)
    local player=type(getSpecificPlayer)=="function"and getSpecificPlayer(playerNum)or nil;if not player then return end
    local _,square=Access.call(backing,"getSquare");if square and luautils.walkAdj(player,square,true)then ISTimedActionQueue.add(Action:new(player,backing,item,active))end
end
local function chooseOrientation(playerNum,backing,item,orientation)
    local player=type(getSpecificPlayer)=="function"and getSpecificPlayer(playerNum)or nil;if not player then return end
    local _,square=Access.call(backing,"getSquare");if square and luautils.walkAdj(player,square,true)then ISTimedActionQueue.add(OrientationAction:new(player,backing,item,orientation))end
end
local function chooseFacing(playerNum,backing,item)
    local player=type(getSpecificPlayer)=="function" and getSpecificPlayer(playerNum) or nil
    local ok,vector=Access.call(player,"getForwardDirection")
    local _,x=Access.call(vector,"getX");local _,y=Access.call(vector,"getY")
    local angle=ok and Direction.fromVector(x,y) or nil
    if angle then chooseOrientation(playerNum,backing,item,angle) end
end
local function addMenu(playerNum,context,worldobjects,test)
    if test then return end
    if lightWorks.Config and lightWorks.Config.EnableWorldEmitters==false then return end
    local backing=findBacking(worldobjects);if not backing then return end
    local _,item=Access.call(backing,"getItem");local desired=not state(item);local _,name=Access.call(item,"getDisplayName")
    local lightName=tostring(name or tr("ContextMenu_lightWorks_GenericLight","Light"))
    local option=context:addOption(desired and tr("ContextMenu_lightWorks_TurnOn","Turn On %1",lightName)
        or tr("ContextMenu_lightWorks_TurnOff","Turn Off %1",lightName),playerNum,choose,backing,item,desired)
    if desired then
        local Power=(rawget(_G,"B47ANCEDPower")or rawget(_G,"powerWorks")or lightWorks.powerWorks);local ok,power=false,nil
        if type(Power)=="table"and type(Power.getConsumerPowerState)=="function"then ok,power=pcall(Power.getConsumerPowerState,item)end
        if not ok or type(power)~="table"or power.known~=true or power.powered~=true then option.notAvailable=true;option.toolTip={description=tr("ContextMenu_lightWorks_ChargedBatteryRequired","A charged compatible battery is required.")}end
    end
    local profile=lightWorks.getLightProfile(item)
    if profile and profile.emitter and profile.emitter.cone==true and rawget(_G,"ISContextMenu")then
        local root=context:addOption(tr("ContextMenu_lightWorks_Aim","Aim %1",lightName),item,nil)
        local sub=ISContextMenu:getNew(context);context:addSubMenu(root,sub)
        sub:addOption(tr("ContextMenu_lightWorks_AimFacing","Aim along your facing"),playerNum,chooseFacing,backing,item)
        local currentData=Access.modData(item);local current=currentData and currentData.lightWorksWorldEmitter and currentData.lightWorksWorldEmitter.orientation
        for _,entry in ipairs({{"ContextMenu_lightWorks_North","North","N"},{"ContextMenu_lightWorks_East","East","E"},{"ContextMenu_lightWorks_South","South","S"},{"ContextMenu_lightWorks_West","West","W"}})do
            local direction=tr(entry[1],entry[2])
            local aim=sub:addOption(direction,playerNum,chooseOrientation,backing,item,entry[3])
            if current==entry[3]then aim.notAvailable=true;aim.toolTip={description=tr("ContextMenu_lightWorks_AlreadyAimed","The light is already aimed %1.",string.lower(direction))}end
        end
    end
end
local function onServerCommand(module,command,args)
    if module~="lightWorks"or(command~="worldEmitterState"and command~="worldEmitterOrientation")or type(args)~="table"then return end
    local resolved
    if type(getCell)=="function"then
        local _,square=Access.call(getCell(),"getGridSquare",args.x,args.y,args.z);local _,objects=Access.call(square,"getWorldObjects");local _,count=Access.call(objects,"size")
        for index=0,math.min(128,math.max(0,tonumber(count)or 0))-1 do local _,backing=Access.call(objects,"get",index);local _,item=Access.call(backing,"getItem");local _,id=Access.call(item,"getID");if id==args.itemId then resolved={backing=backing,item=item};break end end
    end
    if resolved then
        if command=="worldEmitterOrientation" and Direction.normalize(args.orientation)==nil then return end
        if command=="worldEmitterState" and type(args.active)~="boolean" then return end
        local existing=Access.modData(resolved.item)
        if not existing or (existing.lightWorksWorldEmitter~=nil and (type(existing.lightWorksWorldEmitter)~="table" or existing.lightWorksWorldEmitter.schemaVersion~=1)) then return end
        local data=Access.modData(resolved.item);if data then data.lightWorksWorldEmitter=data.lightWorksWorldEmitter or{schemaVersion=1};if command=="worldEmitterState"then data.lightWorksWorldEmitter.active=args.active==true else data.lightWorksWorldEmitter.orientation=args.orientation end end
        if command=="worldEmitterState"then Access.call(resolved.item,"setActivated",args.active==true);Manager.ensure(resolved.backing,args.active==true)else Manager.ensure(resolved.backing,nil,args.orientation)end
    end
end
if Events and Events.OnFillWorldObjectContextMenu then Events.OnFillWorldObjectContextMenu.Add(function(...)local ok,err=pcall(addMenu,...);if not ok then print("[lightWorks] World-light menu error: "..tostring(err))end end)end
if Events and Events.OnServerCommand then Events.OnServerCommand.Add(onServerCommand)end
lightWorks.WorldEmitterToggleAction=Action
lightWorks.WorldEmitterOrientationAction=OrientationAction
return{Action=Action,OrientationAction=OrientationAction,addMenu=addMenu,onServerCommand=onServerCommand,findBacking=findBacking}
