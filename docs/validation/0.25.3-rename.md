# Spectrum rename validation

Project Version: 0.25.3

Date: 2026-10-16 (America/Phoenix)

Scope: compatible display-name rename and repository onboarding. Source identity,
persistence, networking, configuration and dependencies retain their existing
contracts. Existing gameplay is not re-audited or runtime-certified by this task.

## Commands and environment

Use Python 3.12 with `lupa==2.6` from `requirements-dev.txt`:

```sh
python scripts/check_versions.py --root .
python scripts/check_repository.py
python scripts/test_lua.py
python scripts/validate.py
python scripts/check_repository.py --staged
git diff --check
git diff --cached --check
```

The local invocation uses the bundled Python executable at
`C:/Users/willi/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe`
in place of `python`. This machine's unqualified `python` command is a Windows
Store alias. CI uses Python 3.12 on Linux.

## Evidence and runtime gates

- [TESTED, offline] The adopted baseline version inventory passed at `0.25.2`
  before the rename and bump. Current results are recorded after execution below.
- [VERIFIED, source] Display metadata and 29 sandbox page-label values change;
  existing translation keys, Mod ID, Lua namespace, save/protocol keys and
  required `powerWorks` identity are retained. Language folders provide the
  existing English fallback strings; folder/key parity is not a claim of
  independent native-language translations.
- [TESTED, offline] The initial host Lua 5.1 trial passed 24/25 regressions; the
  remaining fixture uses host `table.unpack`, unavailable in Lua 5.1. The runner
  uses unmodified Lua 5.4 for regressions and Lua 5.1 for source syntax separately.
  Neither is the PZ Kahlua runtime.
- [RUNTIME GATE] In-game display, sandbox labels and actual load with `powerWorks`
  need a disposable-save check in the installed game. No PZ game/server was run.
- [RUNTIME GATE] G7 **BLOCKED / NOT TESTED**: dedicated startup, client join/rejoin,
  synchronization, persistence and dedicated restarts need actual evidence.
- [RUNTIME GATE] Stable-release G8 **BLOCKED**. Host/Linux CI checks do not prove
  PZ Linux dedicated-server compatibility or replace G7.
- Packaging, deploy and Workshop upload: **NOT PERFORMED**. Historical packages
  remain unchanged. The new packaging generator was inspected and syntax-checked
  only; its output/integrity path remains NOT TESTED until authorized packaging.

Historical runtime/API audit records remain tied to their original versions and
game builds. Their presence is not current SP or multiplayer proof.

## Current offline results

- [TESTED, offline Windows] `python scripts/validate.py` PASS: canonical/current
  version mirrors, source/identity/path checks, 29 translation/fallback folders,
  32 Lua 5.1 source/template syntax checks and all 25 host Lua 5.4 regressions.
- [TESTED, offline Windows] Repository credential/path scan found no suspected
  secrets or forbidden generated/private files in the 162 selected source,
  documentation, test and setup files. This is a pattern-based audit, not a
  guarantee that every possible credential format is recognizable.
- [TESTED, offline Windows] Current package/provenance checks were explicitly
  deferred because no `dist/current` package exists; no package PASS is claimed.
- [VERIFIED, source diff] Runtime edits are restricted to version/display
  metadata, sandbox page-label values and debug-only presentation. All gameplay
  modules and technical identities retain their baseline behavior.
- [TESTED, offline Windows] All 42 protected legacy packaging-copy/artifact
  hashes match the import ledger. Exactly 33 authoritative source files changed,
  all within the declared metadata, version, page-label and debug-presentation
  scope; existing artwork and the remaining source files are byte-identical.
