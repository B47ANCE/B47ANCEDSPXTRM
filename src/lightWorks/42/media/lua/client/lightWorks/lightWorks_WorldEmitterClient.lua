require "TimedActions/ISDropWorldItemAction"
local Manager=require "lightWorks/lightWorks_WorldEmitterManager"

local function call(object,method,...)
    if not object then return false,nil end
    local ok,fn=pcall(function()return object[method]end)
    if not ok or type(fn)~="function" then return false,nil end
    return pcall(fn,object,...)
end
local function isActive(item)
    for _,method in ipairs({"isActivated","getActivated","isActive"})do local ok,value=call(item,method);if ok then return value==true end end
    return false
end

if ISDropWorldItemAction and not ISDropWorldItemAction.lightWorksWrapped then
    local originalStart=ISDropWorldItemAction.start
    local originalComplete=ISDropWorldItemAction.complete
    function ISDropWorldItemAction:start()
        self.lightWorksPreserveActive=self.item and lightWorks.isRegisteredLight(self.item) and isActive(self.item)
        local ok,dir=call(self.character,"getDir");self.lightWorksPlacementOrientation=ok and tostring(dir) or nil
        if self.item and lightWorks.supportsWorldEmission(self.item) then
            local dataOk,data=call(self.item,"getModData")
            if dataOk and type(data)=="table" then
                data.lightWorksWorldEmitter=type(data.lightWorksWorldEmitter)=="table"and data.lightWorksWorldEmitter or{schemaVersion=1}
                data.lightWorksWorldEmitter.active=self.lightWorksPreserveActive==true
                data.lightWorksWorldEmitter.orientation=self.lightWorksPlacementOrientation
            end
        end
        return originalStart(self)
    end
    function ISDropWorldItemAction:complete()
        local result=originalComplete(self)
        local backing=self.item and self.item.getWorldItem and self.item:getWorldItem() or nil
        if backing then Manager.ensure(backing,self.lightWorksPreserveActive==true,self.lightWorksPlacementOrientation) end
        return result
    end
    ISDropWorldItemAction.lightWorksWrapped=true
end

if Events and Events.OnObjectAboutToBeRemoved then Events.OnObjectAboutToBeRemoved.Add(function(object) Manager.unregister(object) end) end
if Events and Events.OnObjectAdded then Events.OnObjectAdded.Add(function(object) Manager.ensure(object) end) end
if Events and Events.OnTick then Events.OnTick.Add(Manager.onTick) end
if Events and Events.OnCreatePlayer then Events.OnCreatePlayer.Add(function(_,player) Manager.discoverNear(player) end) end

if type(isDebugEnabled)~="function" or isDebugEnabled()==true then
    function LWWorldEmitterInspect(id)
        local report=Manager.inspect(id)
        if not report then print("[lightWorks][WorldEmitter] not found: "..tostring(id));return nil end
        print(string.format("[lightWorks][WorldEmitter] id=%s profile=%s pos=%.1f,%.1f,%.1f facing=%s mode=%s phase=%.2f active=%s powered=%s battery=%s charge=%s rgb=%.3f,%.3f,%.3f radius=%.1f uv=%.2f/%.1f bound=%s%s",
            report.id,report.profileId,report.x,report.y,report.z,tostring(report.orientation),report.mode,report.effectIntensity or 0,tostring(report.active),tostring(report.powered),
            tostring(report.batteryType),report.chargeFraction and string.format("%.1f%%",report.chargeFraction*100)or"unknown",
            report.visibleRGB.r,report.visibleRGB.g,report.visibleRGB.b,report.visibleRadius,report.uvIntensity,report.uvRadius,
            tostring(report.sourceBound),report.colorDesync and " COLOR DESYNC" or ""));return report
    end

    function LWWorldEmitterStatus()
        local reports=Manager.list();print("[lightWorks][WorldEmitter] bound emitters="..tostring(#reports))
        for _,report in ipairs(reports)do LWWorldEmitterInspect(report.id)end
        return reports
    end

    function LWWorldEmitterRescan()
        local found=0
        if type(getSpecificPlayer)=="function" then for i=0,3 do local player=getSpecificPlayer(i);if player then found=found+Manager.discoverNear(player)end end end
        print("[lightWorks][WorldEmitter] rescan candidates="..tostring(found));return found
    end
end

return Manager
