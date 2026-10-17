-- Advisory invalidation only. No persistence, network transport or authority
-- transfer; listeners must query/validate state through its owning API.
local Access=require "lightWorks/lightWorks_ItemAccess"
local Bus={CONTRACT_VERSION=1,MAX_LISTENERS=64,MAX_DELIVERY=128}
local topics={bulb=true,pattern=true,world=true,orientation=true,sunburn=true,
    migration=true,registry=true,sandbox=true,lifecycle=true}
local listeners,queue={},{}
local nextToken,sequence=0,0
local dispatching=false
local metrics={published=0,delivered=0,listenerFailures=0,dropped=0,rejected=0}
local lastFailure
local function finite(v)return type(v)=="number" and v==v and math.abs(v)<math.huge end
local function text(v,limit)return type(v)=="string" and #v>0 and #v<=limit and not v:find("[%c]")end
local function clone(t)local out={};for k,v in pairs(t)do out[k]=type(v)=="table" and clone(v) or v end;return out end
local function scalars(t,allowed,limit)
    if t==nil then return {} end
    if type(t)~="table" then return nil end
    local out,count={},0
    for k,v in pairs(t)do
        count=count+1
        if count>16 or not text(k,64) or (allowed and not allowed[k]) then return nil end
        if not(finite(v) or type(v)=="boolean" or text(v,limit or 128)) then return nil end
        out[k]=v
    end
    return out
end
local function side()
    if type(isServer)=="function" and isServer()==true then return "server" end
    if type(isClient)=="function" then return isClient()==true and "client" or "singleplayer" end
    return "unknown"
end
function Bus.subscribe(topic,id,callback)
    if (topic~="*" and not topics[topic]) or not text(id,128) or type(callback)~="function" then return nil,"invalid subscription" end
    local key=topic..":"..id
    if listeners[key] then return nil,"subscription already exists" end
    local count=0;for _ in pairs(listeners)do count=count+1 end
    if count>=Bus.MAX_LISTENERS then return nil,"listener budget exceeded" end
    nextToken=nextToken+1
    listeners[key]={topic=topic,id=id,callback=callback,token=nextToken}
    return nextToken
end
function Bus.unsubscribe(topic,id,token)
    if not text(topic,128) or not text(id,128) then return false end
    local key=topic..":"..id
    if token~=nil and (not listeners[key] or listeners[key].token~=token) then return false end
    local existed=listeners[key]~=nil;listeners[key]=nil;return existed
end
function Bus.status()
    local result=clone(metrics);local count=0;for _ in pairs(listeners)do count=count+1 end
    result.listeners=count;result.sequence=sequence;result.contractVersion=1
    result.lastFailure=lastFailure and clone(lastFailure) or nil
    return result
end
function Bus.item(item)
    local subject={kind="item"}
    local _,id=Access.call(item,"getID");if finite(id) then subject.id=tostring(id) end
    local _,itemType=Access.call(item,"getFullType");if text(itemType,128) then subject.itemType=itemType end
    return subject
end
function Bus.character(character)
    local subject={kind="character"}
    local _,id=Access.call(character,"getOnlineID")
    if finite(id) and id>=0 and id==math.floor(id) then subject.id=tostring(id) end
    return subject
end
function Bus.publish(topic,action,subject,detail)
    local cleanSubject=scalars(subject,{kind=true,id=true,itemType=true},256)
    local cleanDetail=scalars(detail)
    if not topics[topic] or not text(action,64) or not cleanSubject or not cleanDetail or sequence>=9007199254740990 then
        metrics.rejected=metrics.rejected+1;return false,"invalid notification"
    end
    if #queue>=Bus.MAX_DELIVERY then metrics.dropped=metrics.dropped+1;return false,"notification budget exceeded" end
    sequence=sequence+1;metrics.published=metrics.published+1
    queue[#queue+1]={contractVersion=1,sequence=sequence,topic=topic,action=action,side=side(),subject=cleanSubject,detail=cleanDetail}
    if dispatching then return true end
    dispatching=true
    local processed=0
    while #queue>0 and processed<Bus.MAX_DELIVERY do
        local event=table.remove(queue,1);processed=processed+1
        local selected={}
        for key,listener in pairs(listeners)do
            if listener.topic=="*" or listener.topic==event.topic then selected[#selected+1]={key=key,listener=listener} end
        end
        table.sort(selected,function(a,b)return a.listener.token<b.listener.token end)
        for _,entry in ipairs(selected)do
            if listeners[entry.key]==entry.listener then
                local ok,err=pcall(entry.listener.callback,clone(event))
                if ok then metrics.delivered=metrics.delivered+1
                else
                    metrics.listenerFailures=metrics.listenerFailures+1
                    local readable,message=pcall(tostring,err)
                    lastFailure={listenerId=entry.listener.id,topic=event.topic,
                        error=(readable and message or "listener error could not be formatted"):gsub("[%c]"," "):sub(1,256)}
                end
            end
        end
    end
    if #queue>0 then metrics.dropped=metrics.dropped+#queue;queue={} end
    dispatching=false
    return true
end
-- The public observer surface deliberately omits publishing and subject builders.
Bus.observers={subscribe=Bus.subscribe,unsubscribe=Bus.unsubscribe,status=Bus.status}
return Bus
