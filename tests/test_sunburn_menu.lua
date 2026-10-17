local API=require "lightWorks/lightWorks_API"
local character={data={lightWorksSunburn={schemaVersion=1,dose=.5,severity=.25,lastProtection=.75,lastWorldAgeHours=4}}}
function character:getModData()return self.data end
getSpecificPlayer=function(index)return index==0 and character end
local function context()
    return {options={},addOption=function(self,label)local option={label=label};self.options[#self.options+1]=option;return option end,
        addSubMenu=function(_,root,sub)root.sub=sub end}
end
ISContextMenu={getNew=function()return context()end}
local Menu=require "lightWorks/lightWorks_SunburnMenu"
local c=context();Menu.add(0,c,{},false)
assert(#c.options==1 and #c.options[1].sub.options==3)
assert(c.options[1].sub.options[1].label=="Accumulated sunlight dose: 50%")
assert(c.options[1].sub.options[3].label=="Last sampled protection: 75%")
assert(character.data.lightWorksSunburn.dose==.5,"status must be read-only")
API.Config.EnableSunburn=false;c=context();Menu.add(0,c,{},false);assert(#c.options==0)
print("read-only, local sunburn status and sandbox disable pass")
