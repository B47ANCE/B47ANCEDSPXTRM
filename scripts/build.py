#!/usr/bin/env python3
"""Explicit offline packaging; never deploys, uploads, deletes or launches a game."""
import hashlib
import json
from pathlib import Path, PurePosixPath
import subprocess
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def sha(data):
    return hashlib.sha256(data).hexdigest()


def main():
    subprocess.run([sys.executable, str(ROOT / "scripts/validate.py")], cwd=ROOT, check=True)
    version = (ROOT / "VERSION").read_text().strip()
    output = ROOT / "dist/current"
    if output.exists() and any(output.iterdir()):
        raise SystemExit("dist/current is not empty. Preserve/classify existing outputs before another build; no files were deleted.")
    entries = {}
    for path in sorted((ROOT / "src/B47ANCEDSPXTRM").rglob("*")):
        if path.is_file():
            entries["Contents/mods/" + path.relative_to(ROOT / "src").as_posix()] = path.read_bytes()
    for name in ["workshop.txt", "preview.png"]:
        entries[name] = (ROOT / name).read_bytes()
    folded = set()
    for name in entries:
        path = PurePosixPath(name)
        if path.is_absolute() or ".." in path.parts or "\\" in name or name.casefold() in folded:
            raise SystemExit("Unsafe/duplicate/case-colliding archive path: " + name)
        folded.add(name.casefold())
    output.mkdir(parents=True, exist_ok=True)
    archive = output / f"B47ANCEDSPXTRM-{version}.zip"
    with zipfile.ZipFile(archive, "x", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as package:
        for name, data in sorted(entries.items()):
            info = zipfile.ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            package.writestr(info, data)
    with zipfile.ZipFile(archive) as package:
        if package.testzip() is not None or set(package.namelist()) != set(entries):
            raise SystemExit("Package integrity failure; preserve the failed artifact for inspection.")
        for name, data in entries.items():
            if package.read(name) != data:
                raise SystemExit("Package content differs from source: " + name)
    provenance = {
        "version": version,
        "display_name": "B47ANCED SPXTRM",
        "mod_id": "B47ANCEDSPXTRM",
        "workshop_id": "3788592008",
        "minimum_game_version": "42.20.3",
        "commit": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
        "dirty": bool(subprocess.check_output(["git", "status", "--porcelain"], cwd=ROOT)),
        "package": archive.name,
        "package_sha256": sha(archive.read_bytes()),
        "members_sha256": {name: sha(data) for name, data in sorted(entries.items())},
        "evidence": "Offline source/package checks only; SP and dedicated multiplayer NOT TESTED. G7/G8 BLOCKED.",
    }
    (output / "provenance.json").write_text(json.dumps(provenance, indent=2) + "\n", encoding="utf-8")
    subprocess.run([sys.executable, str(ROOT / "scripts/check_versions.py"), "--release"], cwd=ROOT, check=True)
    print("Created", archive.relative_to(ROOT), provenance["package_sha256"])
    print("Package integrity/version checks do not certify gameplay or authorize publication.")


if __name__ == "__main__":
    main()
