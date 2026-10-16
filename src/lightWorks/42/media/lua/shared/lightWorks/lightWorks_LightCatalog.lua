require "lightWorks/lightWorks_API"

local lightWorks = lightWorks
local Catalog = { entries={}, order={}, built=false, lastBuildReason=nil }
lightWorks.LightCatalog = Catalog

local function call(object, method, default)
    local ok, value = pcall(function()
        local fn = object and object[method]
        if type(fn) ~= "function" then return default end
        return fn(object)
    end)
    if ok and value ~= nil then return value end
    return default
end

local function lower(value) return string.lower(tostring(value or "")) end
local function contains(text, token) return lower(text):find(lower(token),1,true) ~= nil end

local function tagsFor(script)
    local result={}
    local tags=call(script,"getTags",nil)
    if tags then
        local okIter,iterator=pcall(function() return tags:iterator() end)
        if okIter and iterator then
            while true do
                local okHas,has=pcall(function() return iterator:hasNext() end)
                if not okHas or not has then break end
                local okNext,value=pcall(function() return iterator:next() end)
                if okNext and value then result[#result+1]=tostring(value) end
            end
        end
    end
    if #result==0 then
        local size=tags and call(tags,"size",0) or 0
        for i=0,(tonumber(size) or 0)-1 do
            local ok,value=pcall(function() return tags:get(i) end)
            if ok and value then result[#result+1]=tostring(value) end
        end
    end
    return result
end

local function fullTypeFor(script)
    local value=call(script,"getFullName",nil) or call(script,"getFullType",nil)
    if value then return tostring(value) end
    local module=call(script,"getModuleName",nil)
    local name=call(script,"getName",nil)
    if module and name then return tostring(module).."."..tostring(name) end
    return name and tostring(name) or nil
end

local function snapshot(script)
    local cone=call(script,"isTorchCone",call(script,"getTorchCone",nil))
    if type(cone)~="boolean" then cone=nil end
    return {
        fullType=fullTypeFor(script),
        displayName=tostring(call(script,"getDisplayName",call(script,"getName",""))),
        itemType=tostring(call(script,"getItemType",call(script,"getTypeString",call(script,"getType","UNKNOWN")))),
        lightStrength=tonumber(call(script,"getLightStrength",nil)),
        lightDistance=tonumber(call(script,"getLightDistance",nil)),
        torchCone=cone, -- nil is unverified metadata, not a negative native fact.
        tags=tagsFor(script),
        obsolete=call(script,"getObsolete",call(script,"isObsolete",false)) == true,
    }
end

local function evidence(s) return lower(table.concat({s.fullType or "",s.displayName or "",s.itemType or "",table.concat(s.tags," ")}," ")) end

local function hasFlashlightTag(s)
    for _,tag in ipairs(s.tags) do if lower(tag)=="flashlight" then return true end end
    return false
end

local function candidate(s)
    if s.obsolete or not s.fullType then return false end
    local text=evidence(s)
    if contains(text,"lightbulb") or contains(text,"light bulb") then return false end
    return hasFlashlightTag(s) or (s.lightStrength or 0)>0 or (s.lightDistance or 0)>0
        or contains(text,"flashlight") or contains(text,"handtorch")
        or contains(text,"penlight") or contains(text,"gunlight")
end

local function recommend(s)
    local text=evidence(s)
    local family="handheld"
    local confidence=0.60
    local reasons={}
    if hasFlashlightTag(s) then confidence=confidence+0.20; reasons[#reasons+1]="Flashlight tag" end
    if (s.lightStrength or 0)>0 and (s.lightDistance or 0)>0 then confidence=confidence+0.15; reasons[#reasons+1]="positive light strength/distance" end
    if contains(text,"gunlight") or contains(text,"weaponlight") or contains(text,"weapon light") then
        family="weapon"; confidence=math.max(confidence,0.90)
    elseif contains(text,"anglehead") or contains(text,"angle head") or contains(text,"chest") then
        family="attachable"; confidence=math.max(confidence,0.82)
    elseif contains(text,"lantern") then
        family="lantern"; confidence=math.max(confidence,0.72)
    end
    if #reasons==0 then reasons[1]="name or partial light metadata" end
    return {
        family=family,
        status="review",
        confidence=math.min(0.99,confidence),
        reason=table.concat(reasons," + "),
        suggested={
            item=s.fullType,
            displayName=s.displayName,
            defaultBulb="Base.LightBulb",
            tools=family=="handheld" and false or lightWorks.Config.DefaultBulbTools,
        },
    }
end

local function javaItems(list)
    local result={}
    local size=call(list,"size",0)
    for i=0,(tonumber(size) or 0)-1 do
        local ok,item=pcall(function() return list:get(i) end)
        if ok and item then result[#result+1]=item end
    end
    return result
end

function Catalog.build(reason)
    Catalog.entries,Catalog.order={},{}
    Catalog.lastBuildReason=reason or "manual"
    local manager=rawget(_G,"ScriptManager")
    manager=manager and manager.instance or nil
    if not manager then Catalog.built=false; return false,"ScriptManager.instance unavailable" end
    local ok,items=pcall(function() return manager:getAllItems() end)
    if not ok or not items then Catalog.built=false; return false,"ScriptManager:getAllItems unavailable" end
    local scanned,candidates=0,0
    for _,script in ipairs(javaItems(items)) do
        scanned=scanned+1
        local s=snapshot(script)
        if candidate(s) then
            local recommendation=recommend(s)
            local verified=lightWorks.VerifiedLights[s.fullType]
            local entry={fullType=s.fullType,snapshot=s,classification=recommendation,verified=verified~=nil}
            if verified then entry.classification.status="verified"; entry.classification.confidence=1.0 end
            Catalog.entries[s.fullType]=entry
            Catalog.order[#Catalog.order+1]=s.fullType
            candidates=candidates+1
        end
    end
    table.sort(Catalog.order)
    Catalog.built=true
    return true,{scanned=scanned,candidates=candidates,reason=Catalog.lastBuildReason}
end

function Catalog.ensure() if Catalog.built then return true end return Catalog.build("lazy") end
function Catalog.isBuilt() return Catalog.built end
function Catalog.get(fullType) Catalog.ensure(); return Catalog.entries[fullType] end
function Catalog.getAll()
    Catalog.ensure()
    local result={}
    for _,id in ipairs(Catalog.order) do result[#result+1]=Catalog.entries[id] end
    return result
end
function Catalog.getReviewQueue()
    local result={}
    for _,entry in ipairs(Catalog.getAll()) do if not entry.verified then result[#result+1]=entry end end
    return result
end
function Catalog.summary()
    local result={total=0,verified=0,review=0}
    for _,entry in ipairs(Catalog.getAll()) do
        result.total=result.total+1
        if entry.verified then result.verified=result.verified+1 else result.review=result.review+1 end
    end
    return result
end
function Catalog.formatReviewReport()
    local summary=Catalog.summary()
    local lines={string.format("lightWorks Light Catalog: %d candidates | verified=%d | awaiting review=%d",summary.total,summary.verified,summary.review)}
    for _,entry in ipairs(Catalog.getReviewQueue()) do
        local c=entry.classification
        lines[#lines+1]=string.format("%s | %s | type=%s | family=%s | strength=%s | distance=%s | cone=%s | confidence=%.2f | %s",
            entry.fullType,entry.snapshot.displayName,entry.snapshot.itemType,c.family,
            entry.snapshot.lightStrength and string.format("%.3f",entry.snapshot.lightStrength) or "UNKNOWN",
            entry.snapshot.lightDistance and string.format("%.3f",entry.snapshot.lightDistance) or "UNKNOWN",
            entry.snapshot.torchCone==nil and "UNKNOWN" or tostring(entry.snapshot.torchCone),c.confidence,c.reason)
    end
    return table.concat(lines,"\n")
end

function Catalog.exportReviewReport(filename)
    filename=tostring(filename or "lightWorks_LightReview.txt")
    local writerFactory=rawget(_G,"getFileWriter")
    if type(writerFactory)~="function" then return false,"getFileWriter unavailable" end
    local ok,result=pcall(function()
        local writer=writerFactory(filename,true,false)
        if not writer then error("writer unavailable") end
        writer:write(Catalog.formatReviewReport())
        writer:write("\n")
        writer:close()
        return filename
    end)
    if not ok then return false,result end
    return true,result
end

return Catalog
