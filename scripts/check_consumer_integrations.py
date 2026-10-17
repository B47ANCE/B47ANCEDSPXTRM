#!/usr/bin/env python3
"""Execute bounded API probes against explicitly selected read-only consumer source.

Tests do not load complete mod bootstraps or prove engine, loader or MP behavior.
"""
import argparse
import json
import os
from pathlib import Path
from lupa.lua54 import LuaRuntime
from consumer_sources import ROOT, sources, snapshot


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dependencies", type=Path, required=True)
    parser.add_argument("--medical-root", type=Path)
    args = parser.parse_args()
    selected = sources(args.dependencies.resolve(), args.medical_root)
    before = {name: snapshot(*pair) for name, pair in selected.items()}
    os.chdir(ROOT)
    runtime = LuaRuntime(unpack_returned_tuples=True)
    runtime.globals().package.path = ";".join(str(source / "media/lua/shared/?.lua").replace("\\", "/") for _, source in selected.values())
    runtime.execute((ROOT / "tests/integration/consumer_actual_source.lua").read_text(encoding="utf-8"))
    after = {name: snapshot(*pair) for name, pair in selected.items()}
    if before != after:
        raise SystemExit("Source pairing changed during probe; result invalid, rerun")
    print(json.dumps({"result": "PASS", "environment": "host Lua 5.4; native object stubs; API slices only",
                      "sources": after, "fullModLoad": "NOT TESTED", "SP": "NOT TESTED", "dedicated": "NOT TESTED"}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
