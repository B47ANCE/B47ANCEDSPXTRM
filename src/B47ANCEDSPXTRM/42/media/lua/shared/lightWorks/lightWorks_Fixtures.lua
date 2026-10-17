-- Registered fixture adapters report facts; their owning mod retains placement,
-- power, persistence and server mutation. Unknown facts never become emission.
local API=require "lightWorks/lightWorks_API"
local Sources=require "lightWorks/lightWorks_EmissionSources"
local Direction=require "lightWorks/lightWorks_Direction"
local Fixtures={MAX_PROVIDERS=32,providers={}}
local function finite(v) return type(v)=="number" and v==v and math.abs(v)<math.huge end
function Fixtures.register(def)
    assert(type(def)=="table" and type(def.id)=="string" and #def.id>0 and #def.id<=128,"fixture provider ID required")
    assert(type(def.inspect)=="function" and not Fixtures.providers[def.id],"unique fixture inspector required")
    local count=0;for _ in pairs(Fixtures.providers) do count=count+1 end
    assert(count<Fixtures.MAX_PROVIDERS,"fixture provider limit")
    local providerId="lightWorks.fixture."..def.id
    -- Registration is stable; only the original callback's owner state is live.
    local inspect,customPresentation=def.inspect,def.customPresentation==true
    Sources.registerProvider{id=providerId,priority=200,inspect=function(object,context)
        local state=inspect(object,context)
        if state==nil then return nil end
        if API.Config.EnableWorldEmitters==false then return {emitting=false,reason="world emitters disabled"} end
        if type(state)~="table" or state.known~=true or state.active~=true or state.powered~=true then
            return {on=false,powered=false,emitting=false,reason="fixture state incomplete or off"}
        end
        local range,intensity=state.range,state.intensity
        if not finite(range) or range<=0 or range>32 or not finite(intensity) or intensity<0 or intensity>1 then
            return {emitting=false,reason="invalid fixture geometry"}
        end
        local dx,dy=Direction.vector(state.orientation)
        if state.directional==true and not dx then return {emitting=false,reason="fixture orientation unknown"} end
        local uv=state.uv
        if uv~=nil and (type(uv)~="table" or not finite(uv.intensity) or uv.intensity<0 or uv.intensity>100
            or not finite(uv.range) or uv.range<=0 or uv.range>32 or type(uv.spectrum)~="table") then return {emitting=false,reason="invalid fixture UV"} end
        if uv then
            for _,band in ipairs({"uva","uvb","uvc"}) do
                local value=uv.spectrum[band]
                if not finite(value) or value<0 or value>1 then return {emitting=false,reason="invalid fixture spectrum"} end
            end
        end
        local color=uv and API.UV_VISIBLE_COLOR or state.color or {r=1,g=1,b=1}
        for _,key in ipairs({"r","g","b"}) do
            if not finite(color[key]) or color[key]<0 or color[key]>1 then return {emitting=false,reason="invalid fixture color"} end
        end
        return {on=true,powered=true,emitting=intensity>0 or (uv and uv.intensity>0) or false,
            range=range,intensity=intensity,visibleRange=range,visibleIntensity=intensity,
            channels={visible=intensity>0,UV=uv~=nil},uvIntensity=uv and uv.intensity or 0,
            uvRange=uv and uv.range or 0,spectrum=uv and uv.spectrum,
            directional=state.directional==true,orientation=state.orientation,directionX=dx,directionY=dy,
            color={r=color.r,g=color.g,b=color.b},customPresentation=customPresentation}
    end}
    Fixtures.providers[def.id]=providerId
    return true
end
function Fixtures.unregister(id)
    local provider=Fixtures.providers[id];if not provider then return false end
    Fixtures.providers[id]=nil;return Sources.unregisterProvider(provider)
end
API.Fixtures=Fixtures
return Fixtures
