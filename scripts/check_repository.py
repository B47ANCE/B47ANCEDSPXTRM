#!/usr/bin/env python3
"""Read-only source, identity, localization, path and credential checks."""
import argparse
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "src/B47ANCEDSPXTRM/42"
SENSITIVE = {
    "private key": r"-----BEGIN (?:RSA |OPENSSH |EC |DSA )?PRIVATE KEY-----",
    "GitHub credential": r"\b(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,})",
    "AWS access key": r"\b(?:AKIA|ASIA)[A-Z0-9]{16}\b",
    "API secret": r"\bsk-(?:proj-)?[A-Za-z0-9_-]{35,}",
    "credential URL": r"(?:https?|sftp|ssh)://[^\s/@:]+:[^\s/@]+@",
    "credential assignment": r'''(?im)^\s*(?:password|passwd|api_key|apikey|access_token|auth_token|client_secret)\s*[:=]\s*["'][^"'\r\n]{6,}["']''',
}
EXCLUDED_ROOTS = {".agents", ".codex", ".test-deps", "Contents", "dist", "__pycache__"}
EXCLUDED_NAMES = {".steamcmd-last-upload.sha256", "SHA256SUMS.txt", "console.txt", ".env"}
EXCLUDED_SUFFIXES = {".pem", ".key", ".pfx", ".vdf", ".log", ".zip", ".pyc", ".db"}


def git(*args):
    return subprocess.check_output(["git", *args], cwd=ROOT)


def unique_json(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError("duplicate JSON key: " + key)
        result[key] = value
    return result


def credentials(staged=False):
    args = ("diff", "--cached", "--name-only", "--diff-filter=ACMR", "-z") if staged else ("ls-files", "--cached", "--others", "--exclude-standard", "-z")
    names = sorted(set(git(*args).decode().strip("\0").split("\0")) - {""})
    errors = []
    cases = {}
    for name in names:
        path = Path(name)
        if (path.parts[0] in EXCLUDED_ROOTS or name in EXCLUDED_NAMES
                or path.suffix.lower() in EXCLUDED_SUFFIXES or path.name.startswith((".env.", "local.settings", "server-console"))):
            errors.append("Excluded/private/generated path selected for Git: " + name)
        if name.casefold() in cases and cases[name.casefold()] != name:
            errors.append("Case-colliding paths: " + name + " / " + cases[name.casefold()])
        cases[name.casefold()] = name
        data = git("show", ":" + name) if staged else (ROOT / name).read_bytes()
        if b"\0" in data:
            continue
        text = data.decode("utf-8-sig", errors="replace")
        for label, pattern in SENSITIVE.items():
            for match in re.finditer(pattern, text):
                line = text.count("\n", 0, match.start()) + 1
                errors.append(f"Suspected {label}: {name}:{line} (value withheld)")
    print(f"Credential/path scan: {len(names)} selected files; {len(errors)} findings")
    return errors


def source_checks():
    errors = []
    info = dict(line.split("=", 1) for line in (SOURCE / "mod.info").read_text().splitlines() if "=" in line)
    expected = {"name": "B47ANCED SPXTRM", "id": "B47ANCEDSPXTRM", "require": "B47ANCEDPower", "versionMin": "42.20.3"}
    for key, value in expected.items():
        if info.get(key) != value:
            errors.append("Unexpected mod identity/dependency field: " + key)
    if (ROOT / "WORKSHOP_ID.txt").read_text().strip() != "3788592008":
        errors.append("Existing Workshop ID changed")
    forbidden = {".java", ".jar", ".class", ".dll", ".exe", ".so", ".dylib"}
    for path in (ROOT / "src").rglob("*"):
        if path.is_symlink():
            errors.append("Symlink in runtime source: " + path.relative_to(ROOT).as_posix())
        if path.suffix.lower() in forbidden:
            errors.append("Non-Lua runtime dependency: " + path.relative_to(ROOT).as_posix())

    lua_root = SOURCE / "media/lua"
    modules = {p.relative_to(lua_root / side).with_suffix("").as_posix() for side in ["shared", "client", "server"] for p in (lua_root / side).rglob("*.lua")}
    for path in lua_root.rglob("*.lua"):
        for name in re.findall(r'''\brequire\s*\(?\s*["']([^"']+)["']''', path.read_text(encoding="utf-8")):
            if name.lower().startswith(("lightworks/", "b47ancedspxtrm/")) and name not in modules:
                errors.append(f"Missing/case-incorrect owned require {name} in {path.name}")

    translation_root = lua_root / "shared/Translate"
    languages = sorted(p.name for p in translation_root.iterdir() if p.is_dir())
    inventory = json.loads((ROOT / "SOURCE_INVENTORY.json").read_text())
    if languages != inventory["translation_languages"]:
        errors.append("Translation language inventory drift")
    keys = set()
    for filename in ["Sandbox.json", "ContextMenu.json"]:
        english = json.loads((translation_root / "EN" / filename).read_text(), object_pairs_hook=unique_json)
        keys.update(english)
        for language in languages:
            data = json.loads((translation_root / language / filename).read_text(), object_pairs_hook=unique_json)
            if set(data) != set(english) or any(not isinstance(v, str) or not v.strip() for v in data.values()):
                errors.append(f"Translation keys/values incomplete: {language}/{filename}")
            if filename == "Sandbox.json" and data.get("Sandbox_lightWorks") != "B47ANCED SPXTRM":
                errors.append("Stale sandbox display name: " + language)
    for path in lua_root.rglob("*.lua"):
        used = set(re.findall(r'''["']((?:ContextMenu|Sandbox)_lightWorks(?:_[A-Za-z0-9]+)*)["']''', path.read_text()))
        for missing in used - keys:
            errors.append(f"Missing owned translation key {missing} in {path.name}")
    # The native settings UI and the server's schema must describe the same
    # configurable behavior; a drift here can make displayed bounds misleading.
    declarations = {}
    for name, body in re.findall(r"option lightWorks\.(\w+)\s*\{([^}]+)\}", (SOURCE / "media/sandbox-options.txt").read_text()):
        fields = dict(re.findall(r"(\w+)\s*=\s*([\w.-]+)", body))
        declarations[name] = {k: fields[k] for k in ["type", "default", "min", "max"] if k in fields}
        for suffix in ["", "_tooltip"]:
            if "Sandbox_lightWorks_" + name + suffix not in keys:
                errors.append("Sandbox label/tooltip missing: " + name + suffix)
    runtime_schema = {}
    schema_text = (lua_root / "shared/lightWorks/lightWorks_Sandbox.lua").read_text()
    for name, body in re.findall(r'^\s+(\w+)=\{([^}]+)\},$', schema_text, re.M):
        fields = {}
        for key, quoted, plain in re.findall(r'(\w+)=(?:"([^"]+)"|([\w.-]+))', body):
            fields["type" if key == "kind" else key] = quoted or plain
        runtime_schema[name] = fields
    def normalized(schema):
        return {name: {key: float(value) if key in {"min", "max"} or (key == "default" and value not in {"true", "false"}) else value
                       for key, value in fields.items()} for name, fields in schema.items()}
    if normalized(declarations) != normalized(runtime_schema):
        errors.append("Native sandbox options and runtime validation schema differ")
    descriptions = [(ROOT / p).read_text(encoding="utf-8") for p in ["WORKSHOP_DESCRIPTION.txt", "docs/STEAM_WORKSHOP_DESCRIPTION.txt"]]
    workshop_lines = (ROOT / "workshop.txt").read_text(encoding="utf-8").splitlines()
    rendered = "\n".join(line[len("description="):] for line in workshop_lines if line.startswith("description=")) + "\n"
    if descriptions[0] != descriptions[1] or rendered != descriptions[0]:
        errors.append("Workshop description mirrors differ")
    if "title=B47ANCED SPXTRM" not in workshop_lines:
        errors.append("Workshop title was not renamed")
    if "[b]Mod ID:[/b] B47ANCEDSPXTRM" not in descriptions[0] or "[b]Workshop ID:[/b] 3788592008" not in descriptions[0]:
        errors.append("Workshop identity contract changed")
    if "https://github.com/B47ANCE/B47ANCEDSPXTRM" not in descriptions[0]:
        errors.append("Workshop source link missing")
    if "\\n" in descriptions[0] or "\\n" in (ROOT / "WORKSHOP_CHANGE_NOTE.txt").read_text():
        errors.append("Workshop text contains serialized paragraph escapes")
    print(f"Identity, Lua-only source, owned require paths and {len(languages)} translation/fallback folders checked")
    return errors


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--staged", action="store_true", help="Audit exact staged blobs rather than working files")
    args = parser.parse_args()
    try:
        errors = credentials(args.staged) + source_checks()
    except (OSError, ValueError, KeyError, subprocess.CalledProcessError) as error:
        errors = ["Repository check could not complete: " + str(error)]
    for error in errors:
        print("FAIL:", error)
    print("Repository static checks " + ("FAIL" if errors else "PASS (no runtime certification)"))
    return int(bool(errors))


if __name__ == "__main__":
    raise SystemExit(main())
