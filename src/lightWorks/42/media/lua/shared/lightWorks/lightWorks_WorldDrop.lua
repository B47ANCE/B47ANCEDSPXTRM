require "TimedActions/ISDropWorldItemAction"
local API=require "lightWorks/lightWorks_API"
local Access=require "lightWorks/lightWorks_ItemAccess"
local WorldPower=require "lightWorks/lightWorks_WorldPower"
local Drop={}
local function authority()
    if type(isServer)=="function" and isServer()==true then return true end
    return not(type(isClient)=="function" and isClient()==true)
end
local function active(item)
    for _,method in ipairs({"isActivated","getActivated","isActive"}) do
        local ok,value=Access.call(item,method);if ok then return value==true end
    end
    return false
end

function Drop.install()
    if not ISDropWorldItemAction or type(ISDropWorldItemAction.complete)~="function" then return false end
    if ISDropWorldItemAction.lightWorksAuthorityDropWrapped then return true end
    local original=ISDropWorldItemAction.complete
    function ISDropWorldItemAction:complete()
        if not authority() or not self.item or not API.supportsWorldEmission(self.item) then return original(self) end
        local item=self.item;local data=Access.modData(item)
        if type(data)~="table" then return false end
        local previous=data.lightWorksWorldEmitter
        local got,direction=Access.call(self.character,"getDir")
        local initialized,reason=WorldPower.initializePlacement(item,active(item),got and tostring(direction) or nil)
        if not initialized then
            print("[lightWorks] Drop state initialization rejected: "..tostring(reason))
            return false
        end
        -- Native completion transmits the world item internally, so initialize
        -- before delegating. No client-only renderer is loaded on this path.
        local ok,result=pcall(original,self)
        local _,backing=Access.call(item,"getWorldItem")
        if backing then WorldPower.prepareBacking(backing,item)
        else data.lightWorksWorldEmitter=previous end
        if not ok then error(result,0) end -- preserve the real native failure
        return result
    end
    ISDropWorldItemAction.lightWorksAuthorityDropWrapped=true
    return true
end

Drop.install()
API.WorldDrop=Drop
return Drop
