require "ISUI/ISUIElement"
local API=require "lightWorks/lightWorks_API"
local Lasers=require "lightWorks/lightWorks_Lasers"
local Players=require "lightWorks/lightWorks_Players"
local Occlusion=require "lightWorks/lightWorks_UVOcclusion"
local Renderer={panels={},samples={},MAX_LASERS=16}
local Panel=ISUIElement:derive("lightWorks_LaserPanel")
function Panel:render()
    if API.Config.EnableLasers==false or not isoToScreenX or not isoToScreenY then return end
    self:setStencilRect(0,0,self.width,self.height)
    for _,ray in ipairs(Renderer.samples[self.playerIndex] or {}) do
        local source,target=ray.source,ray.endpoint
        local x=isoToScreenX(self.playerIndex,target.x,target.y,target.z)-self.x
        local y=isoToScreenY(self.playerIndex,target.x,target.y,target.z)-self.y
        self:drawRect(x-1,y-1,3,3,1,ray.color.r,ray.color.g,ray.color.b)
        if ray.showBeam and API.Config.EnableLaserBeams==true then
            local sx=isoToScreenX(self.playerIndex,source.x,source.y,source.z)-self.x
            local sy=isoToScreenY(self.playerIndex,source.x,source.y,source.z)-self.y
            self:drawLine2(sx,sy,x,y,.35,ray.color.r,ray.color.g,ray.color.b)
        end
    end
    self:clearStencilRect()
end
-- Geometry is sampled at a bounded cadence; draw callbacks only project/cache.
function Renderer.sample()
    Renderer.samples={}
    if API.Config.EnableLasers==false then return end
    local cell=getCell and getCell();if not cell then return end
    local rays={}
    for _,owner in ipairs(Players.collect(true)) do
        local ray=Lasers.forPlayer(owner,cell)
        if ray then rays[#rays+1]=ray;if #rays>=Renderer.MAX_LASERS then break end end
    end
    for index=0,3 do
        local viewer=getSpecificPlayer(index)
        if viewer then
            local samples={};Renderer.samples[index]=samples
            local origin={x=viewer:getX(),y=viewer:getY(),z=viewer:getZ()}
            for _,ray in ipairs(rays) do
                if math.floor(origin.z)==math.floor(ray.source.z) and
                    Occlusion.trace(cell,origin,ray.endpoint,{windowTransmission=1})==1 then
                    samples[#samples+1]={source=ray.source,endpoint=ray.endpoint,color=ray.color,
                        showBeam=Occlusion.trace(cell,origin,ray.source,{windowTransmission=1})==1}
                end
            end
        end
    end
end
function Renderer.refresh()
    for index=0,3 do
        local player=getSpecificPlayer(index)
        local panel=Renderer.panels[index]
        if player then
            if not panel then
                panel=Panel:new(0,0,1,1);panel.playerIndex=index
                panel:initialise();panel:instantiate();panel:addToUIManager()
                panel:setWantKeyEvents(false);panel:setWantMouseEvents(false)
                Renderer.panels[index]=panel
            end
            panel:setX(getPlayerScreenLeft(index));panel:setY(getPlayerScreenTop(index))
            panel:setWidth(getPlayerScreenWidth(index));panel:setHeight(getPlayerScreenHeight(index))
        elseif panel then panel:removeFromUIManager();Renderer.panels[index]=nil end
    end
end
if Events and Events.OnTick then
    local tick=0
    Events.OnTick.Add(function() tick=tick+1;if tick%6==0 then Renderer.sample() end;if tick%30==0 then Renderer.refresh() end end)
end
return Renderer
