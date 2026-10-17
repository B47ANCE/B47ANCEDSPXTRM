-- Material semantics are independent of the renderer. A reaction is a visual
-- hint, never proof of identity or authorization for shared gameplay effects.
local Materials={CONTRACT_VERSION=1,MAX_MATERIALS=64}
local registry={}
local modes={absorption=true,fluorescence=true,reflectance=true}
local function finite(v) return type(v)=="number" and v==v and math.abs(v)<math.huge end
local function bounded(v,min,max) return finite(v) and v>=min and v<=max end
function Materials.register(def)
    assert(type(def)=="table" and type(def.id)=="string" and #def.id>0 and #def.id<=128 and not def.id:find("[%c]"),"material ID required")
    assert(not registry[def.id] and modes[def.response],"unique material and supported response required")
    assert(bounded(def.threshold,.001,100) and bounded(def.strength,0,1),"bounded reaction threshold/strength required")
    local bands,color={},{}
    for _,band in ipairs({"uva","uvb","uvc"}) do
        local v=def.excitation and def.excitation[band];assert(bounded(v,0,1),"complete excitation bands required");bands[band]=v
    end
    assert(bands.uva+bands.uvb+bands.uvc>0,"nonzero excitation required")
    for _,key in ipairs({"r","g","b"}) do
        local v=def.color and def.color[key];assert(bounded(v,0,1),"bounded reaction color required");color[key]=v
    end
    local count=0;for _ in pairs(registry) do count=count+1 end
    assert(count<Materials.MAX_MATERIALS,"material registry capacity")
    registry[def.id]={id=def.id,response=def.response,threshold=def.threshold,strength=def.strength,excitation=bands,color=color}
    return true
end
function Materials.evaluate(id,sample)
    local p=registry[id];if not p then return nil,"unknown material" end
    if type(sample)~="table" or sample.artificialComplete~=true or type(sample.uv)~="table" then return nil,"complete artificial exposure required" end
    local excitation=0
    for _,band in ipairs({"uva","uvb","uvc"}) do
        local value=sample.uv[band];if not bounded(value,0,1000000) then return nil,"invalid exposure" end
        excitation=excitation+value*p.excitation[band]
    end
    local fraction=math.min(1,excitation/(p.threshold*4))
    return {contractVersion=1,materialId=id,response=p.response,active=excitation>=p.threshold,
        strength=excitation>=p.threshold and p.strength*fraction or 0,
        color={r=p.color.r,g=p.color.g,b=p.color.b},identityConfirmed=false}
end
-- Whole untreated blood is an absorption target, not fluorescent paint.
Materials.register{id="lightWorks.UntreatedBlood",response="absorption",threshold=.02,strength=.35,
    excitation={uva=1,uvb=0,uvc=0},color={r=.055,g=.008,b=.012}}
Materials.register{id="lightWorks.FluorescentMarker",response="fluorescence",threshold=.02,strength=.65,
    excitation={uva=1,uvb=0,uvc=0},color={r=.15,g=.7,b=1}}
return Materials
