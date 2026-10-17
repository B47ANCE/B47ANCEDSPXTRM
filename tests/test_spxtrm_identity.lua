local old=require "lightWorks/lightWorks_API"
local current=require "B47ANCEDSPXTRM/API"
assert(old==current and B47ANCEDSPXTRM==lightWorks and old.MOD_ID=="B47ANCEDSPXTRM")
assert(old.MODDATA_KEY=="lightWorks","activation rename must not split save ownership")
local file=assert(io.open("src/B47ANCEDSPXTRM/42/mod.info"));local text=file:read("*a");file:close()
assert(text:find("\nid=B47ANCEDSPXTRM\n",1,true) and text:find("\nrequire=B47ANCEDPower\n",1,true))
assert(not text:find("\nid=lightWorks\n",1,true),"no invented engine Mod ID alias")
print("SPXTRM activation migration retains a single shared API/save namespace")
