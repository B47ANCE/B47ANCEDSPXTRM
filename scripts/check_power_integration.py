#!/usr/bin/env python3
"""Read-only host integration against an explicitly selected B47ANCEDPower source.

Does not copy that project, start PZ, deploy or inspect player saves.
"""
import argparse
import hashlib
import os
from pathlib import Path
import subprocess

from lupa.lua54 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dependency-root", type=Path, required=True)
    args = parser.parse_args()
    dependency = args.dependency_root.resolve()
    shared = dependency / "src/B47ANCEDPower/42/media/lua/shared"
    api = shared / "B47ANCEDPower/API.lua"
    if not api.is_file():
        parser.error("Selected source does not expose B47ANCEDPower/API.lua")
    os.chdir(ROOT)
    runtime = LuaRuntime(unpack_returned_tuples=True)
    runtime.globals().package.path = (
        str(shared / "?.lua").replace("\\", "/") + ";"
        + str(ROOT / "src/B47ANCEDSPXTRM/42/media/lua/shared/?.lua").replace("\\", "/")
    )
    runtime.execute("""
        local API=require "lightWorks/lightWorks_API"
        require "lightWorks/lightWorks_Vanilla"
        require "lightWorks/lightWorks_FirstPartyContent"
        require "lightWorks/lightWorks_Patterns"
        require "lightWorks/lightWorks_powerWorks"
        assert(API.registerPowerProfiles(),"maintained power contract rejected")
        assert(API.powerWorks==B47ANCEDPower and powerWorks==nil,"no legacy alias may be required")
        for _,kind in ipairs({"UVAInspectionLamp","UVCServiceLamp","GrowLamp"}) do
            assert(B47ANCEDPower.isRegisteredConsumer("lightWorks."..kind),"specialist power profile missing")
        end
        local data={B47ANCEDPower={batteryType="Base.Battery",baseUseDelta=.001,
            capacity=2.5,resistance=1}}
        local item={fraction=1,useDelta=.001,active=true}
        function item:getFullType()return "Base.Torch"end
        function item:getModData()return data end
        function item:getID()return 42 end
        function item:isActivated()return self.active end
        function item:setActivated(v)self.active=v end
        function item:getUsedDelta()return self.fraction end
        function item:setUsedDelta(v)self.fraction=v end
        function item:getUseDelta()return self.useDelta end
        function item:setUseDelta(v)self.useDelta=v end
        assert(B47ANCEDPower.isRegisteredConsumer(item))
        assert(B47ANCEDPower.getConsumerPowerState(item).powered)
        assert(B47ANCEDPower.refreshConsumer(item))
        local before=B47ANCEDPower.getConsumerEnergyRatePerHour(item)
        assert(before>0)
        assert(API.Patterns.set(item,"strobe","integration-pattern"))
        local patterned=B47ANCEDPower.getConsumerEnergyRatePerHour(item)
        assert(patterned>0 and patterned<before,"pattern duty must reach actual power demand")
        API.Config.EnableLightPatterns=false
        assert(B47ANCEDPower.getConsumerEnergyRatePerHour(item)==before)
        data.lightWorksWorldEmitter={schemaVersion=1,active=true,lastPowerUpdateHours=1}
        local WorldPower=require "lightWorks/lightWorks_WorldPower"
        assert(WorldPower.updateItem(item,2))
        assert(item.fraction<1 and data.lightWorksWorldEmitter.lastPowerUpdateHours==2)
        data.B47ANCEDPowerEnergyRecovery={schemaVersion=1}
        assert(not B47ANCEDPower.getConsumerPowerState(item).powered)
        assert(not WorldPower.updateItem(item,3))
        assert(data.lightWorksWorldEmitter.lastPowerUpdateHours==2,"failed debit must retain debt")
    """)
    sha = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=dependency, text=True).strip()
    dirty = bool(subprocess.check_output(["git", "status", "--porcelain"], cwd=dependency))
    digest = hashlib.sha256()
    for file in sorted(shared.rglob("*.lua")):
        digest.update(file.relative_to(shared).as_posix().encode())
        digest.update(b"\0")
        digest.update(file.read_bytes())
    print("PASS offline actual-source Power integration (engine item stubs; not PZ runtime)")
    print("Dependency HEAD:", sha, "dirty:", dirty)
    print("Dependency shared Lua tree SHA-256:", digest.hexdigest())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
