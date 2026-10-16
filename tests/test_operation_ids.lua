local Operations=require "lightWorks/lightWorks_Operations"
assert(Operations.new("PATTERN")==nil,"missing native UUID support must fail closed")
getRandomUUID=function()error("unavailable")end
assert(Operations.new("WORLD")==nil,"generator failure cannot fall back to a colliding counter")
getRandomUUID=function()return "bad-id"end
assert(Operations.new("WORLD")==nil,"malformed generated values cannot enter the protocol")
local counter=0
getRandomUUID=function()counter=counter+1;return string.format("00000000-0000-4000-8000-%012d",counter)end
local first=assert(Operations.new("PATTERN"))
package.loaded["lightWorks/lightWorks_Operations"]=nil
local reloaded=require "lightWorks/lightWorks_Operations"
local second=assert(reloaded.new("PATTERN"))
assert(first~=second and #first<=128 and #second<=128,"module reload must not reset operation identity")
assert(Operations.new(string.rep("A",17))==nil,"internal prefixes must stay bounded")
print("lightWorks opaque operation identity and unavailable-generator checks passed")
