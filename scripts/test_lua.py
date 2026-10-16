#!/usr/bin/env python3
"""Offline Lua syntax/regressions only; never starts Project Zomboid."""
import os
from pathlib import Path

from lupa.lua51 import LuaRuntime as Lua51
from lupa.lua54 import LuaRuntime as Lua54

ROOT = Path(__file__).resolve().parents[1]
BASE = "src/lightWorks/42/media/lua/"


def source(side, name):
    return BASE + side + "/lightWorks/lightWorks_" + name + ".lua"


def shared(name):
    return source("shared", name)


def client(name):
    return source("client", name)


ARGUMENTS = {
    "test_colored_torches": [client("ColoredTorches")],
    "test_context_menu": [shared("API"), client("ContextMenu")],
    "test_emitter_profiles": [shared("API"), shared("Vanilla")],
    "test_light_catalog": [shared("API"), shared("LightCatalog")],
    "test_low_power_flicker": [shared("LowPowerFlicker")],
    "test_patterns": [shared("Patterns")],
    "test_pattern_menu": [shared("API"), shared("ItemAccess"), shared("Patterns"), client("PatternMenu")],
    "test_pattern_server": [shared("API"), shared("ItemAccess"), shared("Patterns"), source("server", "PatternServer")],
    "test_sunburn": [shared("Sunburn")],
    "test_uv_reaction_prototype": [client("UVReactionPrototype")],
    "test_world_lamp_menu": [client("WorldLampMenu")],
}


def main():
    os.chdir(ROOT)
    failed = []
    syntax = Lua51(unpack_returned_tuples=True)
    compile_file = syntax.eval("function(path) local fn, err = loadfile(path); return fn ~= nil, err end")
    lua_files = sorted((ROOT / "src").rglob("*.lua")) + sorted((ROOT / "compatibility-template").rglob("*.lua"))
    for path in lua_files:
        ok, error = compile_file(path.relative_to(ROOT).as_posix())
        if not ok:
            failed.append(path.name)
            print("FAIL syntax:", path.relative_to(ROOT), error)
    print(f"Lua 5.1 syntax: {len(lua_files)} files, {len(failed)} failures")

    tests = sorted((ROOT / "tests").glob("test_*.lua"))
    if not tests:
        raise SystemExit("No Lua regression tests found")
    for path in tests:
        runtime = Lua54(unpack_returned_tuples=True)
        runtime.globals().arg = runtime.table_from(ARGUMENTS.get(path.stem, []))
        output = []
        runtime.globals().print = lambda *args: output.append(" ".join(map(str, args)))
        runtime.globals().package.path = ";".join(BASE + side + "/?.lua" for side in ["shared", "client", "server"])
        try:
            runtime.execute(path.read_text(encoding="utf-8"), name=path.relative_to(ROOT).as_posix())
            print("PASS", path.name)
        except Exception as error:
            failed.append(path.name)
            print("FAIL", path.name, error)
            for line in output[-5:]:
                print("  " + line)
    print(f"Host Lua 5.4 regressions: {len(tests)} tests; total failures: {len(failed)}")
    print("Offline execution is not PZ/Kahlua, single-player, or dedicated multiplayer evidence.")
    return int(bool(failed))


if __name__ == "__main__":
    raise SystemExit(main())
