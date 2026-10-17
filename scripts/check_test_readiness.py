#!/usr/bin/env python3
"""Read-only source dependency preflight, not game/deployment/release verification."""
import argparse
import json
import re
from pathlib import Path
from consumer_sources import sources, metadata, snapshot

PROFILES = {
    "core": ["spectrum", "power"],
    "nightfall": ["spectrum", "power", "nightfall", "mortis", "knowledge", "medical"],
    "consumers": ["spectrum", "power", "mortis", "knowledge", "medical", "water", "farming"],
}
OWNED = {"spectrum": "lightWorks", "power": "B47ANCEDPower", "nightfall": "ProjectNightfall",
         "mortis": "Mortis", "knowledge": "B47ANCEDKnowledgeAndWisdom", "medical": "medWorks",
         "water": "waterWorks", "farming": "farmWorks"}


def check(selected):
    issues, identities = [], {}
    for name, (repository, source) in selected.items():
        if not (source / "mod.info").is_file():
            issues.append(f"{name}: authoritative mod.info unavailable")
            continue
        info = metadata(source)
        canonical = repository / "VERSION"
        if canonical.is_file() and canonical.read_text(encoding="utf-8-sig").strip() != info.get("modversion"):
            issues.append(f"{name}: canonical VERSION and modversion differ")
        if not info.get("id") or info["id"] in identities:
            issues.append(f"{name}: missing/duplicate Mod ID")
        identities[info.get("id")] = (name, info)
        modules = {p.relative_to(source / "media/lua" / side).with_suffix("").as_posix()
                   for side in ("shared", "client", "server")
                   for p in (source / "media/lua" / side).rglob("*.lua")}
        # Only owned namespaces and the known retired dependency are resolved;
        # this is not a speculative validator of vanilla engine modules.
        for path in (source / "media/lua").rglob("*.lua"):
            text = path.read_text(encoding="utf-8-sig")
            for module in re.findall(r'''\brequire\s*\(?\s*["']([^"']+)["']''', text):
                if module.split("/")[0].casefold() == OWNED[name].casefold() and module not in modules:
                    issues.append(f"{name}: missing/case-incorrect owned module {module} ({path.name})")
                if module.startswith("experienceWorks/"):
                    issues.append(f"{name}: retired experienceWorks import ({path.name})")
        if any(p.suffix.lower() in {".java", ".jar", ".class", ".dll", ".exe"} for p in source.rglob("*")):
            issues.append(f"{name}: non-Lua runtime dependency")
    for name, info in identities.values():
        for required in filter(None, (s.strip() for s in info.get("require", "").split(","))):
            if required not in identities:
                issues.append(f"{name}: required Mod ID {required} absent from selected source set")
    return sorted(set(issues))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dependencies", type=Path, required=True)
    parser.add_argument("--profile", choices=PROFILES, default="core")
    parser.add_argument("--medical-root", type=Path)
    args = parser.parse_args()
    available = sources(args.dependencies.resolve(), args.medical_root)
    selected = {name: available[name] for name in PROFILES[args.profile]}
    before = {name: snapshot(*pair) for name, pair in selected.items() if (pair[1] / "mod.info").is_file()}
    issues = check(selected)
    after = {name: snapshot(*pair) for name, pair in selected.items() if (pair[1] / "mod.info").is_file()}
    if before != after:
        issues.append("Source set changed during preflight; rerun against a stable pairing")
    print(json.dumps({"profile": args.profile, "sourcePreflight": "BLOCKED" if issues else "PASS",
                      "issues": issues, "sources": after, "SP": "NOT TESTED", "G7": "BLOCKED / NOT TESTED",
                      "stableG8": "BLOCKED", "deployment": "NOT PERFORMED"}, indent=2))
    return int(bool(issues))


if __name__ == "__main__":
    raise SystemExit(main())
