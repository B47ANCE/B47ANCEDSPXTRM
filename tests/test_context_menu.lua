dofile(arg[1])
local callback=nil
local realRequire=require
require=function(name)
    if name=='lightWorks/lightWorks_API' or name=='lightWorks/lightWorks_Vanilla' or name=='lightWorks/lightWorks_powerWorks' or name=='lightWorks/lightWorks_ChangeBulbAction' or name=='TimedActions/ISTimedActionQueue' then return true end
    return realRequire(name)
end

Events={OnFillInventoryObjectContextMenu={Add=function(fn) callback=fn end}}
local nestedAdded=0
local nestedLabels={}
ISContextMenu={getNew=function() return {
    addOption=function(_,label) nestedAdded=nestedAdded+1; nestedLabels[#nestedLabels+1]=label; return {} end,
    addSubMenu=function() end,
} end}
local player={}
getSpecificPlayer=function() return player end
getText=function(key)
    if key=="ContextMenu_lightWorks_RemoveBulb" then return "Localized Remove Bulb" end
    return key
end

dofile(arg[2])
assert(type(callback)=='function','context callback must register')

local hostile=setmetatable({}, {__index=function() error('unknown mod wrapper') end})
assert(pcall(callback,0,{addOption=function() error('must not add') end},{hostile}),
    'unknown/modded inventory entries must never escape the context boundary')

lightWorks.registerLight({item='Test.MenuLight',tools=false})
local light={getFullType=function() return 'Test.MenuLight' end,getModData=function() return {} end}
local added=0
local rootLabel=nil
local context={addOption=function(_,label) added=added+1; rootLabel=label; return {} end,addSubMenu=function() end}
assert(pcall(callback,0,context,{light}),'supported light menu construction must be nil-safe')
assert(added==1 and rootLabel=='Test.MenuLight','servicing must live beneath the light item menu')
assert(nestedAdded==1,'supported occupied light must expose nested remove action')
assert(nestedLabels[1]=='Localized Remove Bulb','bulb actions must use translation keys')

local existingAdded=0
local existingMenu={addOption=function() existingAdded=existingAdded+1; return {} end,addSubMenu=function() end}
local existingOption={name='Test.MenuLight',subOption=7}
local reusedContext={
    addOption=function() error('must reuse the existing item submenu') end,
    addSubMenu=function() error('must not create a duplicate item submenu') end,
    getOptionFromName=function(_,name) return name=='Test.MenuLight' and existingOption or nil end,
    getSubMenu=function(_,number) return number==7 and existingMenu or nil end,
}
assert(pcall(callback,0,reusedContext,{light}),'existing vanilla item submenu reuse must be nil-safe')
assert(existingAdded==1,'lightWorks remove action must be merged into the existing item submenu')

powerWorks=setmetatable({}, {__index=function() error('lightWorks must not own or inspect battery menus') end})
local isolatedMenu={addOption=function() return {} end,addSubMenu=function() end}
local isolatedContext={addOption=function() return {} end,addSubMenu=function() end}
ISContextMenu.getNew=function() return isolatedMenu end
assert(pcall(callback,0,isolatedContext,{light}),'lightWorks bulb menu must remain independent of powerWorks menu APIs')
print('lightWorks context-menu isolation checks passed')
