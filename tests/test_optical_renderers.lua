local API={Config={EnableLasers=true,EnableLaserBeams=true,EnableWorldEmitters=true,EnableColoredLightRenderer=true}}
package.loaded["lightWorks/lightWorks_API"]=API
local origin={x=1,y=1,z=0}
local player={getX=function()return 1 end,getY=function()return 1 end,getZ=function()return 0 end}
getSpecificPlayer=function(i)if i==0 then return player end end
getPlayerScreenLeft=function()return 0 end;getPlayerScreenTop=function()return 0 end
getPlayerScreenWidth=function()return 800 end;getPlayerScreenHeight=function()return 600 end
getCell=function()return {}end
isoToScreenX=function(_,x)return x*20 end;isoToScreenY=function(_,x,y)return y*20 end
local rays=0;local disconnected=false
package.loaded["lightWorks/lightWorks_Lasers"]={forPlayer=function()
    rays=rays+1
    if not disconnected then return {source=origin,endpoint={x=5,y=1,z=0},color={r=1,g=0,b=0}}end
end}
package.loaded["lightWorks/lightWorks_Players"]={collect=function()return {player}end}
package.loaded["lightWorks/lightWorks_UVOcclusion"]={trace=function()return 1 end}
local drawn,removed=0,0
ISUIElement={}
function ISUIElement:derive()local cls={};cls.__index=cls;setmetatable(cls,{__index=self});return cls end
function ISUIElement:new(x,y,w,h)return setmetatable({x=x,y=y,width=w,height=h},{__index=self})end
for _,name in ipairs({"initialise","instantiate","addToUIManager","setWantKeyEvents","setWantMouseEvents","setStencilRect","clearStencilRect"})do ISUIElement[name]=function()end end
for _,name in ipairs({"X","Y","Width","Height"})do local key=name:sub(1,1):lower()..name:sub(2);ISUIElement["set"..name]=function(self,v)self[key]=v end end
function ISUIElement:drawRect()drawn=drawn+1 end;function ISUIElement:drawLine2()drawn=drawn+1 end
function ISUIElement:removeFromUIManager()removed=removed+1 end
package.loaded["ISUI/ISUIElement"]=true
Events={OnTick={Add=function()end},OnObjectAboutToBeRemoved={Add=function()end}}
local LaserRenderer=require "lightWorks/lightWorks_LaserRenderer"
LaserRenderer.refresh();LaserRenderer.sample();assert(#LaserRenderer.samples[0]==1)
LaserRenderer.panels[0]:render();LaserRenderer.panels[0]:render()
assert(drawn==4 and rays==1,"render frames must use cached rays rather than new world scans")
disconnected=true;LaserRenderer.sample();assert(#LaserRenderer.samples[0]==0)
API.Config.EnableLasers=false;LaserRenderer.sample();LaserRenderer.panels[0]:render();assert(drawn==4)
getSpecificPlayer=function()return nil end;LaserRenderer.refresh();assert(removed==1 and not LaserRenderer.panels[0])

local sourceObject={};local on=true;local cleaned=0
local source={providerId="lightWorks.fixture.test",object=sourceObject,customPresentation=true,x=1,y=1,z=0,range=5,intensity=.5,color={r=1,g=0,b=0}}
package.loaded["lightWorks/lightWorks_EmissionSources"]={collectWorld=function()return on and {source}or {}end}
package.loaded["lightWorks/lightWorks_Fixtures"]=true
package.loaded["lightWorks/lightWorks_VanillaEmitterAdapter"]={create=function()return {}end,removeAll=function()cleaned=cleaned+1 end}
getSpecificPlayer=function(i)if i==0 then return player end end
local Fixtures=require "lightWorks/lightWorks_FixtureRenderer"
Fixtures.refresh();assert(Fixtures.records[sourceObject])
Fixtures.refresh();assert(cleaned==0,"same fixture snapshot must not recreate sources")
on=false;Fixtures.refresh();assert(cleaned==1 and not Fixtures.records[sourceObject])
on=true;Fixtures.refresh();API.Config.EnableWorldEmitters=false;Fixtures.refresh()
assert(cleaned==2 and not Fixtures.records[sourceObject],"disable must clean fixture sources")
print("optical renderer cadence, disconnect, idempotence and disable cleanup pass")
