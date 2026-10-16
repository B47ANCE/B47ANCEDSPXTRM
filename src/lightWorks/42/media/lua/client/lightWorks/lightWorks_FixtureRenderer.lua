local API=require "lightWorks/lightWorks_API"
require "lightWorks/lightWorks_Fixtures"
local Sources=require "lightWorks/lightWorks_EmissionSources"
local Adapter=require "lightWorks/lightWorks_VanillaEmitterAdapter"
local Renderer={records={},MAX_SOURCES=64,tick=0}
local function remove(record) Adapter.removeAll(record.sources) end
function Renderer.refresh()
    local seen,count={},0
    if API.Config.EnableWorldEmitters~=false and API.Config.EnableColoredLightRenderer~=false then
        for index=0,3 do
            local player=getSpecificPlayer and getSpecificPlayer(index)
            if player then
                for _,source in ipairs(Sources.collectWorld(player,12,128)) do
                    if source.customPresentation==true and type(source.providerId)=="string"
                        and source.providerId:sub(1,19)=="lightWorks.fixture." and not seen[source.object] and count<Renderer.MAX_SOURCES then
                        seen[source.object]=true;count=count+1
                        local old=Renderer.records[source.object]
                        local c=source.color
                        local signature=table.concat({source.x,source.y,source.z,source.range,source.intensity,
                            c.r,c.g,c.b,tostring(source.orientation),tostring(source.directional)},":")
                        if not old or old.signature~=signature then
                            if old then remove(old) end
                            local radius=source.range*math.sqrt(source.intensity)
                            local created
                            if source.directional then
                                created=Adapter.createDirectional(source.x,source.y,source.z,c,
                                    {radius=source.range,nodes=4,width=.5,falloff=.72},source.intensity,source.orientation)
                            else
                                local light=radius>0 and Adapter.create(source.x,source.y,source.z,c,radius)
                                created=light and {light} or nil
                            end
                            Renderer.records[source.object]={sources=created,signature=created and signature or nil}
                        end
                    end
                end
            end
        end
    end
    for object,record in pairs(Renderer.records) do
        if not seen[object] then remove(record);Renderer.records[object]=nil end
    end
end
function Renderer.onTick()
    Renderer.tick=Renderer.tick+1
    if Renderer.tick%120==0 then Renderer.refresh() end
end
if Events and Events.OnTick then Events.OnTick.Add(Renderer.onTick) end
if Events and Events.OnObjectAboutToBeRemoved then Events.OnObjectAboutToBeRemoved.Add(function(object)
    local record=Renderer.records[object];if record then remove(record);Renderer.records[object]=nil end
end) end
return Renderer
