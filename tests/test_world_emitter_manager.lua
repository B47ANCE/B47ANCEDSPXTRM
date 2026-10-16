local calls={created=0,added=0,removed=0}
local cell={
    addLamppost=function(_,source)calls.added=calls.added+1 end,
    removeLamppost=function(_,source)calls.removed=calls.removed+1 end,
    getGridSquare=function(_,x,y,z)return{x=x,y=y,z=z,CalculateVisionBlocked=function()return false end}end,
}
getCell=function()return cell end
IsoLightSource={new=function(x,y,z,r,g,b,radius)
    calls.created=calls.created+1
    return{x=x,y=y,z=z,r=r,g=g,b=b,radius=radius}
end}
Events={OnGameStart={Add=function()end},OnServerStarted={Add=function()end}}

require "lightWorks/lightWorks_API"
lightWorks.registerBulb({item="Test.WorldUVBulb",emissions={UV={intensity=0.8,range=9}},visibleColor={r=1,g=0,b=1}})
lightWorks.registerLight({item="Test.WorldLight",defaultBulb="Test.WorldUVBulb",emitter={range=9,strength=0.7,cone=true,nodes=4,width=0.7,falloff=0.72}})

local item={active=true,modData={lightWorks={installedBulb="Test.WorldUVBulb"},lightWorksWorldEmitter={schemaVersion=1,orientation="E"}}}
function item:getFullType()return"Test.WorldLight"end
function item:getModData()return self.modData end
function item:getID()return 77 end
function item:isActivated()return self.active end
function item:setActivated(value)self.active=value end

local backing={exists=true,item=item}
function backing:getItem()return self.item end
function backing:getSquare()return self.exists and{}or nil end
function backing:getX()return 10.5 end
function backing:getY()return 20.5 end
function backing:getZ()return 0 end
function backing:isExistInTheWorld()return self.exists end
function backing:setMovedThumpable(value)self.movedThumpable=value end
function backing:getThumpCondition()return 1 end

local Manager=require "lightWorks/lightWorks_WorldEmitterManager"
local first=assert(Manager.ensure(backing))
assert(first.source,"active dropped light must bind a real source")
assert(first.sources and #first.sources==4,"directional world light must bind a bounded visible source chain")
assert(first.sources[1].x<=first.sources[2].x and first.sources[2].x<=first.sources[4].x,"east aiming must advance the visible chain east")
assert(backing.movedThumpable==true,"active world lights must expose a physical thump target")
assert(calls.created==4 and calls.added==4,"one backing object must create one bounded directional chain")
local second=assert(Manager.ensure(backing))
assert(second==first and calls.created==4,"repeated discovery must be idempotent")
local report=assert(Manager.inspect(first.id))
assert(report.uvIntensity==0.8 and report.uvRadius==9,"world emitter must expose UV semantics")
assert(report.visibleRGB.r==0 and report.visibleRGB.g==0 and report.visibleRGB.b==1,"UV renderer must use canonical RGB")
assert(report.colorDesync==false,"canonical UV must not report a color desync")

item.active=false
Manager.ensure(backing,false)
assert(first.source==nil and calls.removed==4,"turning a dropped light off must remove every directional source")
assert(backing.movedThumpable==false,"inactive world lights must not remain a den-defense target")
item.active=true;Manager.ensure(backing,true)
assert(calls.created==8,"turning it back on must restore exactly one bounded chain")
backing.exists=false;Manager.reconcile()
assert(Manager.inspect(first.id)==nil and calls.removed==8,"pickup/removal must unregister and clean the source chain")

backing.exists=true;item.active=true
local rebound=assert(Manager.ensure(backing,true));assert(rebound.source)
local removedBefore=calls.removed
item.modData.lightWorks.hasExplicitBulbState=true;item.modData.lightWorks.installedBulb=nil
Manager.ensure(backing);Manager.reconcile()
assert(not rebound.source and calls.removed>removedBefore and Manager.inspect(rebound.id)==nil,
    "a removed/burned bulb must unregister every prior visible source")
assert(backing.movedThumpable==false,"bulbless backings cannot remain attackable")
print("lightWorks idempotent world-emitter lifecycle and bulbless cleanup checks passed")
