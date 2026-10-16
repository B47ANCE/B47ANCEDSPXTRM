local lightWorks={Config={EnableLightPatterns=true},getLightProfile=function()return{emitter={}}end,
    isRegisteredLight=function()return true end}
package.loaded["lightWorks/lightWorks_API"]=lightWorks
local refreshed=0
powerWorks={refreshConsumer=function()refreshed=refreshed+1;return true end}
local Patterns=dofile(arg[1])
local item={data={},getID=function()return 10 end,getModData=function(self)return self.data end}

assert(Patterns.evaluate(item,0)==1 and Patterns.getDutyCycle(item)==1,"steady must be the safe default")
local set,result=Patterns.set(item,"strobe","pattern-1")
assert(set and result.dutyCycle==.5 and refreshed==1,"pattern change must refresh average power demand")
assert(Patterns.evaluate(item,0)==1 and Patterns.evaluate(item,300)==0,"strobe must alternate on/off deterministically")
assert(not Patterns.set(item,"strobe","pattern-1"),"pattern operations must reject replay")
assert(Patterns.set(item,"pulse","pattern-2"))
local low=Patterns.evaluate(item,0);local high=Patterns.evaluate(item,1000)
assert(low<high and low>=.2 and high<=1,"pulse must vary bounded intensity")
assert(Patterns.set(item,"sos","pattern-3"))
local sawOn,sawOff=false,false
for time=0,Patterns.get("sos").periodMs-1,100 do local value=Patterns.evaluate(item,time);sawOn=sawOn or value>0;sawOff=sawOff or value==0 end
assert(sawOn and sawOff,"SOS must contain signal and gap segments")
Patterns.register{id="test.bad",periodMs=1000,dutyCycle=.5,evaluate=function()error("provider")end}
assert(Patterns.set(item,"test.bad","pattern-4") and Patterns.evaluate(item,0)==0,"throwing patterns must fail dark without breaking the renderer")
lightWorks.Config.EnableLightPatterns=false;assert(Patterns.evaluate(item,0)==1,"sandbox disable must force steady output")
isClient=function()return true end
assert(not Patterns.set(item,"steady","client"),"clients must not mutate canonical pattern state")
print("lightWorks persistent lighting-pattern and average-demand checks passed")
