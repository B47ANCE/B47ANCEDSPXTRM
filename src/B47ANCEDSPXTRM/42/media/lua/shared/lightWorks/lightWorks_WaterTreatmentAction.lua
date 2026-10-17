require "TimedActions/ISBaseTimedAction"
local API=require "lightWorks/lightWorks_API"
local Access=require "lightWorks/lightWorks_ItemAccess"
local Consumers=require "lightWorks/lightWorks_ConsumerIntegrations"
local Exposure=require "lightWorks/lightWorks_ConsumerExposure"
local Operations=require "lightWorks/lightWorks_Operations"
local Water={}
local function finite(v)return type(v)=="number" and v==v and math.abs(v)<math.huge end
function Water.validate(actor,owner)
    if API.Config.EnableWaterUVIntegration~=true then return false end
    local alive,dead=Access.call(actor,"isDead");if not alive or dead~=false then return false end
    local object=owner
    local got,backing=Access.call(owner,"getWorldItem")
    if got and backing then
        local ok,item=Access.call(backing,"getItem");if not ok or item~=owner then return false end
        object=backing
    end
    local placed,square=Access.call(object,"getSquare")
    local indexOk,index=Access.call(object,"getObjectIndex")
    if not placed or not square or not indexOk or not finite(index) or index<0 or index~=math.floor(index) then return false end
    local point=Exposure.position(owner)
    local _,x=Access.call(actor,"getX");local _,y=Access.call(actor,"getY");local _,z=Access.call(actor,"getZ")
    if not point or not finite(x) or not finite(y) or not finite(z)
        or math.floor(z)~=math.floor(point.z) or (x-point.x)^2+(y-point.y)^2>9 then return false end
    -- Native timed actions may call isValid every update. Keep this path free
    -- of optical/world scans; the owner transaction samples at commit time.
    return true
end
function Water.preview(actor,owner)
    return Water.validate(actor,owner) and Consumers.inspectWaterTreatment(owner)==true
end
local Action=ISBaseTimedAction:derive("lightWorks_WaterTreatmentAction")
-- Global identity is required by native Build 42 shared-action dispatch.
lightWorks_WaterTreatmentAction=Action
function Action:isValid() return Water.validate(self.character,self.owner) end
function Action:getDuration() return API.Config.WaterUVTreatmentSeconds*50 end
function Action:start() self:setActionAnim("Loot");self:setAnimVariable("LootPosition","Mid") end
function Action:complete()
    if self.completed or (type(isClient)=="function" and isClient()==true) then return false end
    self.completed=true
    if not self:isValid() then return false end
    -- Allocate on authority, never accept an intensity, coordinate or operation
    -- history from a client. Water owns commit/rollback, persistence and sync.
    local operation=Operations.new("WATER")
    if not operation then return false end
    return Consumers.treatWater(self.owner,operation)==true
end
function Action:perform() ISBaseTimedAction.perform(self) end
function Action:new(actor,owner)
    local o=ISBaseTimedAction.new(self,actor);o.owner=owner;o.completed=false
    o.stopOnWalk=true;o.stopOnRun=true;o.maxTime=o:getDuration();return o
end
Water.Action=Action
return Water
