local API=require "lightWorks/lightWorks_API"
API=lightWorks
local data={lightWorks={baseVisibleCaptured=true,hasExplicitBulbState=true,
    installedBulb="Test.Old",burnMinutes=1234,burnedOut=true,lastBurnedBulbType="Test.Old",custom={value=7}}}
local active=true
local item={getModData=function() return data end,isActivated=function() return active end,
    setActivated=function(_,value) active=value end}
local snapshot=assert(API.captureServiceState(item))
data.lightWorks.burnMinutes=0; data.lightWorks.burnedOut=false
data.lightWorks.installedBulb="Test.New"; data.lightWorks.custom.value=99
active=false
local applied=0
API.applyVisibleProfile=function() applied=applied+1 end
assert(API.restoreServiceState(item,snapshot))
assert(data.lightWorks.burnMinutes==1234 and data.lightWorks.burnedOut)
assert(data.lightWorks.installedBulb=="Test.Old" and data.lightWorks.lastBurnedBulbType=="Test.Old")
assert(data.lightWorks.custom.value==7 and active and applied==1)
snapshot.state.custom.value=500
assert(data.lightWorks.custom.value==7,"restoration must not retain mutable snapshot references")
assert(not API.restoreServiceState(item,{}))
print("lightWorks rollback restores wear, burnout, custom state and activation")
