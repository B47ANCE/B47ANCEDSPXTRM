require "TimedActions/ISBaseTimedAction"
require "lightWorks/lightWorks_API"

local lightWorks = lightWorks
local Access = require "lightWorks/lightWorks_ItemAccess"
local RECOVERY_KEY="lightWorksServiceRecovery"

lightWorks.ChangeBulbAction = ISBaseTimedAction:derive("lightWorks_ChangeBulbAction")
lightWorks_ChangeBulbAction=lightWorks.ChangeBulbAction

function lightWorks.ChangeBulbAction:isValid()
    if not self.character or not self.lightItem then return false end
    local data=Access.modData(self.lightItem)
    if not data or (data[RECOVERY_KEY]~=nil and data[RECOVERY_KEY]~=self._serviceRecord) then return false end
    if self.parentWeapon or self.partId then
        if Access.resolveWeaponPart(self.character,self.parentWeapon,self.partId)~=self.lightItem then return false end
    end
    local okDead,dead=Access.call(self.character,"isDead")
    if not okDead or dead~=false or not Access.ownsItem(self.character,self.lightItem) then return false end

    local canService = lightWorks.canServiceLight(self.character, self.lightItem)
    if not canService then return false end

    if self.mode == "install" then
        if not self.bulbType then return false end
        local replacement=lightWorks.findFirstInventoryItem(self.character,self.bulbType)
        if not replacement or not Access.ownsItem(self.character,replacement) then return false end
        return lightWorks.isCompatible(self.lightItem, self.bulbType)
    end

    if self.mode == "remove" then
        return lightWorks.hasBulb(self.lightItem)
    end

    return false
end

function lightWorks.ChangeBulbAction:update()
    if self.lightItem and self.lightItem.setJobDelta then
        self.lightItem:setJobDelta(self:getJobDelta())
    end
end

function lightWorks.ChangeBulbAction:start()
    if self.lightItem and self.lightItem.setJobType then
        self.lightItem:setJobType(self.mode == "remove" and "Removing Bulb" or "Changing Bulb")
    end
    if self.lightItem and self.lightItem.setJobDelta then
        self.lightItem:setJobDelta(0.0)
    end
end

function lightWorks.ChangeBulbAction:stop()
    if self.lightItem and self.lightItem.setJobDelta then
        self.lightItem:setJobDelta(0.0)
    end
    ISBaseTimedAction.stop(self)
end

function lightWorks.ChangeBulbAction:perform()
    if self.lightItem and self.lightItem.setJobDelta then
        self.lightItem:setJobDelta(0.0)
    end

    ISBaseTimedAction.perform(self)
end

local function commit(self)
    local snapshot=lightWorks.captureServiceState(self.lightItem)
    if not snapshot then return false,true end
    self._serviceRecord.snapshot=snapshot
    if self.mode == "install" then
        local bulbItem = lightWorks.findFirstInventoryItem(self.character, self.bulbType)
        if bulbItem then
            local _,sourceContainer=Access.call(bulbItem,"getContainer")
            local _,replacementId=Access.call(bulbItem,"getID")
            self._serviceRecord.replacementId=replacementId
            -- Consume the physical replacement before mutating the light. The old
            -- order could duplicate a bulb when a nested item moved between
            -- validation and completion, and could not roll an empty light back.
            local removed,removeReason=Access.removeItem(self.character,bulbItem)
            if removed then
                local ok, oldBulb = lightWorks.installBulb(self.lightItem, self.bulbType)
                if ok then
                    local output,addReason
                    if oldBulb then output,addReason=Access.addItem(self.character,oldBulb) end
                    if oldBulb and not output then
                        if addReason=="uncertain" then return false,false end
                        -- Returning the displaced bulb is part of the transaction.
                        -- Restore it and return the replacement if insertion fails.
                        local restored=lightWorks.restoreServiceState(self.lightItem,snapshot)
                        local returned=Access.returnItem(self.character,bulbItem,sourceContainer)
                        return false,restored==true and returned==true
                    end
                    return true
                else
                    -- Compatibility/state may have changed during the action.
                    -- Return the consumed replacement instead of losing it.
                    local restored=lightWorks.restoreServiceState(self.lightItem,snapshot)
                    local returned=Access.returnItem(self.character,bulbItem,sourceContainer)
                    return false,restored==true and returned==true
                end
            end
            return false,removeReason~="uncertain"
        end
    elseif self.mode == "remove" then
        local ok, removedBulb = lightWorks.removeBulb(self.lightItem)
        if ok and removedBulb then
            local output,reason=Access.addItem(self.character,removedBulb)
            if not output then
                if reason=="uncertain" then return false,false end
                -- Inventory insertion failed; restore the light rather than lose
                -- the installed bulb.
                return false,lightWorks.restoreServiceState(self.lightItem,snapshot)==true
            end
            return true
        end
        return false,lightWorks.restoreServiceState(self.lightItem,snapshot)==true
    end

    return false,true
end

function lightWorks.ChangeBulbAction:complete()
    if type(isClient)=="function" and isClient()
        and not (type(isServer)=="function" and isServer()) then return false end
    if self._attempted then return false end
    local data=Access.modData(self.lightItem)
    if type(data)~="table" or data[RECOVERY_KEY]~=nil then return false end
    self._serviceRecord={schemaVersion=1,status="executing",mode=self.mode,bulbType=self.bulbType}
    data[RECOVERY_KEY]=self._serviceRecord
    local checked,valid=pcall(self.isValid,self)
    if not checked or not valid then data[RECOVERY_KEY]=nil; self._serviceRecord=nil; return false end
    self._attempted=true
    local called,success,recovered=pcall(commit,self)
    if called and (success==true or recovered==true) then data[RECOVERY_KEY]=nil
    else self._serviceRecord.status="inspection_required" end
    if not Access.syncServiceState(self.character,self.lightItem,self.parentWeapon) then
        pcall(print,"[lightWorks] Service state sync request failed; do not repeat the committed action")
    end
    if not called or success~=true then
        pcall(print,"[lightWorks] Bulb completion failed; inspect state before retry")
        return false
    end
    return true
end

function lightWorks.ChangeBulbAction:new(character, targetItem, mode, bulbType, parentWeapon, partId)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    -- Constructor names are the native network payload keys. Never serialize a
    -- mounted part as a standalone inventory item with no container.
    if targetItem and not parentWeapon then
        parentWeapon,partId=Access.findWeaponForPart(character,targetItem)
        if parentWeapon then targetItem=nil end
    end
    o.targetItem=targetItem
    o.parentWeapon=parentWeapon
    o.partId=partId
    o.lightItem=parentWeapon and Access.resolveWeaponPart(character,parentWeapon,partId) or targetItem
    o.mode = mode
    o.bulbType = bulbType
    o.stopOnWalk = true
    o.stopOnRun = true
    if mode == "remove" then
        o.maxTime = lightWorks.getRemoveBulbTime(o.lightItem)
    else
        -- "Change Bulb" is remove+install when occupied, install-only when empty.
        o.maxTime = lightWorks.getChangeBulbTime(o.lightItem)
    end

    if character and character.isTimedActionInstant and character:isTimedActionInstant() then
        o.maxTime = 1
    end

    return o
end
