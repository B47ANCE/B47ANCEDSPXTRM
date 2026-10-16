"""Explicit read-only first-party source layouts; never selects staging as source."""
import hashlib
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
LAYOUTS = {
    "spectrum": (None, "src/lightWorks/42"),
    "power": ("B47ANCEDPower", "src/B47ANCEDPower/42"),
    "nightfall": ("Project Nightfall", "src/ProjectNightfall/42"),
    "mortis": ("Project MORTIS", "src/ProjectMORTIS/42"),
    "knowledge": ("B47ANCEDKnowledgeAndWisdom", "src/B47ANCEDKnowledgeAndWisdom/42"),
    "medical": ("B47ANCEDHealthCare", "src/B47ANCEDHealthCare/42"),
    "water": ("waterWorks", "Contents/mods/waterWorks/42"),
    "farming": ("farmWorks", "Contents/mods/farmWorks/42"),
}


def sources(dependencies, medical_root=None):
    result = {}
    for name, (folder, source) in LAYOUTS.items():
        repository = ROOT if folder is None else dependencies / folder
        if name == "medical" and medical_root is not None:
            repository = medical_root
        result[name] = (repository, repository / source)
    return result


def metadata(source):
    return dict(line.split("=", 1) for line in (source / "mod.info").read_text(encoding="utf-8-sig").splitlines() if "=" in line)


def fingerprint(source):
    digest = hashlib.sha256()
    for path in sorted(p for p in source.rglob("*") if p.is_file()):
        digest.update(path.relative_to(source).as_posix().encode())
        digest.update(b"\0")
        digest.update(path.read_bytes())
    return digest.hexdigest()


def snapshot(repository, source):
    info = metadata(source)
    result = {"id": info.get("id"), "declaredVersion": info.get("modversion"),
              "sourceSHA256": fingerprint(source), "sourceFiles": sum(p.is_file() for p in source.rglob("*"))}
    if (repository / ".git").exists():
        result["head"] = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=repository, text=True).strip()
        result["dirty"] = bool(subprocess.check_output(["git", "status", "--porcelain"], cwd=repository))
    else:
        result["head"] = None
        result["versionStatus"] = "legacy metadata only; no canonical version adopted by Spectrum"
    return result
