#!/usr/bin/env python3
"""Run offline development checks without packaging, deployment or runtime launch."""
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]

if __name__ == "__main__":
    for script in ["check_versions.py", "check_repository.py", "test_lua.py"]:
        print("RUN python scripts/" + script, flush=True)
        result = subprocess.run([sys.executable, str(ROOT / "scripts" / script)], cwd=ROOT)
        if result.returncode:
            raise SystemExit(result.returncode)
    print("Offline checks PASS. SP/dedicated runtime and stable release remain separate gates.")
