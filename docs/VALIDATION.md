# Nine-defect fix validation

Project Version: 0.25.5

Date: 2026-10-16 (America/Phoenix)

Scope: fixes for the nine defects audited at 886f97d, implemented on the clean
0.25.4 source aecc9db. See [AUDIT_FIXES.md](AUDIT_FIXES.md) for the root causes,
ownership/persistence decisions, regression map and dedicated test plan.

## Evidence

- [TESTED, offline Windows] All nine original audit probes reproduced before fixes.
- [TESTED, offline Windows] Eight regression files failed before implementation;
  the world-power settlement file exercises two defects. The resulting suite
  passes all 29 host Lua 5.4 regression files and 35 Lua 5.1 source/template syntax
  checks. Lua host execution is not PZ Kahlua or multiplayer runtime evidence.
- [TESTED, offline Windows] Version/repository checks PASS (174 selected files).
  The targeted staged credential/path scan inspected 44 changed files with zero
  findings; unstaged/staged whitespace checks PASS. Freshness REVIEW was solely
  the intended audited changes: no upstream/default-branch commits were missing.
- [TESTED, offline Windows] Installed vanilla drop Lua from Steam build 25485521
  was executed in memory with engine stubs and the actual shared hook. State was
  initialized before transmission; no client renderer loaded. Full game version
  remains UNKNOWN. No raw game source is redistributed.
- [VERIFIED, source] Existing sandbox and schema-1 identifiers remain. No new
  gameplay setting is needed; internal caps/UUID bounds are implementation limits.
- [TESTED, offline Windows] All current artwork bytes match aecc9db, including the
  user-supplied full-resolution source, preview/thumbnail pair and existing icon.
- [VERIFIED, history] [0.25.4 validation](validation/0.25.4-thumbnail.md) is preserved
  byte-for-byte. Earlier validation remains tied to its actual iteration.

## Commands

```sh
python scripts/check_versions.py --root .
python scripts/validate.py
python scripts/check_repository.py --staged
git diff --check
git diff --cached --check
```

Locally, use the bundled executable instead of this machine's Windows Store
`python` alias:
`C:/Users/willi/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe`.
The installed-source-only probe is retained outside Git at
`C:/Users/willi/.codex/tmp/b47anced-spectrum-fix-20261016/native_drop_probe.py`;
invoke it with the repository and installed-game-root paths as its two arguments.
It reads local vanilla Lua in memory and uses stubs; it never starts PZ.

## Runtime gates

SP and dedicated multiplayer are NOT TESTED. G7 is BLOCKED / NOT TESTED and
stable-release G8 BLOCKED. No package, deploy, Workshop upload or game/server
launch was performed. The existing `powerWorks` dependency contract is retained;
the local migrated B47ANCEDPower checkout is not a validated replacement. The
two additional timing/remote-render observations remain outside this nine-fix
scope. See the dedicated plan and dependency notes in AUDIT_FIXES.md.
