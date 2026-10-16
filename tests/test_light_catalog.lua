local apiPath,catalogPath=arg[1],arg[2]
dofile(apiPath)
local realRequire=require
require=function(name)
    if name=="lightWorks/lightWorks_API" then return lightWorks end
    return realRequire(name)
end

local function list(values)
    return { size=function() return #values end, get=function(_,i) return values[i+1] end }
end

local function script(def)
    return {
        getFullName=function() return def.fullType end,
        getDisplayName=function() return def.displayName end,
        getTypeString=function() return def.itemType or "Drainable" end,
        getLightStrength=function() return def.strength or 0 end,
        getLightDistance=function() return def.distance or 0 end,
        getTorchCone=function() return def.cone == true end,
        getTags=function() return list(def.tags or {}) end,
        getObsolete=function() return false end,
    }
end

local candidates=list({
    script({fullType="CoolLights.TacticalFlashlight",displayName="Tactical Flashlight",strength=1.5,distance=18,cone=true,tags={"Flashlight"}}),
    script({fullType="CoolLights.LightBulbUV",displayName="UV Light Bulb",strength=1,distance=5}),
    script({fullType="Base.Spoon",displayName="Spoon"}),
})

ScriptManager={instance={getAllItems=function() return candidates end}}
dofile(catalogPath)

local ok,result=lightWorks.LightCatalog.build("host-test")
assert(ok and result.scanned==3 and result.candidates==1)
local review=lightWorks.LightCatalog.getReviewQueue()
assert(#review==1 and review[1].fullType=="CoolLights.TacticalFlashlight")
assert(lightWorks.isRegisteredLight("CoolLights.TacticalFlashlight")==false,"discovery must not silently enable compatibility")

lightWorks.registerLightCompatibilityProvider({id="lightWorks.CoolLights",targetModId="CoolLights",verified=true})
lightWorks.registerVerifiedLight("lightWorks.CoolLights",review[1].classification.suggested)
assert(lightWorks.isRegisteredLight("CoolLights.TacticalFlashlight"))
assert(lightWorks.getVerifiedLight("CoolLights.TacticalFlashlight").targetModId=="CoolLights")
assert(#lightWorks.LightCatalog.getReviewQueue()==0,"late verified patches must leave the review queue")

local output=""
getFileWriter=function()
    return {write=function(_,text) output=output..text end,close=function() end}
end
local exported,name=lightWorks.LightCatalog.exportReviewReport("review.txt")
assert(exported and name=="review.txt" and output:find("verified=1",1,true),"review report must be exportable")

print("lightWorks light catalog checks passed")

-- Current script-item shape: no InventoryItem light getters are invented.
local nativeScript={getFullName=function()return "Audit.NativeFlashlight"end,
    getDisplayName=function()return "Native Flashlight"end,getItemType=function()return "Drainable"end,
    getObsolete=function()return false end,
    getTags=function()return {iterator=function()
        local pending=true
        return {hasNext=function()return pending end,next=function()pending=false;return "Flashlight"end}
    end}end}
ScriptManager.instance.getAllItems=function()return list({nativeScript})end
assert(lightWorks.LightCatalog.build("current-script-shape"))
local nativeEntry=assert(lightWorks.LightCatalog.get("Audit.NativeFlashlight"))
assert(nativeEntry.snapshot.lightStrength==nil and nativeEntry.snapshot.lightDistance==nil
    and nativeEntry.snapshot.torchCone==nil,"unavailable native metadata must stay UNKNOWN")
assert(nativeEntry.snapshot.itemType=="Drainable","current getItemType route must be used")
local nativeReport=lightWorks.LightCatalog.formatReviewReport()
assert(nativeReport:find("strength=UNKNOWN",1,true) and nativeReport:find("cone=UNKNOWN",1,true),
    "review output must not fabricate zero strength or a false cone flag")
