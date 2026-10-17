# Consumer integration iteration validation

Project Version: 0.27.0

Date: 2026-10-16 (America/Phoenix)
Base: 7fd163b5a43b4d46d9ed760d52fba8f0300ce5a9 (0.26.0).
Branch: feature/spectrum-consumers; stacked PR base: feature/spectrum-roadmap.
Compatibility: MINOR, optional consumer APIs and sandbox configuration.

## Current evidence

- [TESTED, offline Windows] python scripts/validate.py PASS: 41 host Lua 5.4
  regression files; 49 Lua 5.1 source/template syntax files; disposable Python
  preflight test; version, identity, Lua-only, owned require case, 29 language
  fallback/schema checks and credential/path audit (216 selected files, 0 findings).
  The historical nine defects remain covered. Host Lua is not PZ/Kahlua.
- [TESTED, offline Windows] Actual-source consumer API probe PASS: both Nightfall
  bulb registrations and stored-field migration with wear, actual Medical procedure
  reduction/replay, actual Water refusal/transaction/rollback, read-only native
  crop-provider observation and client mutation refusal. No first-party API is
  replaced by a compatibility shim. Native objects are stubs. Full mod bootstraps,
  native inventory/fluids, loader and dedicated availability are NOT TESTED.
- [TESTED, offline Windows] Actual-source B47ANCEDPower probe PASS: profiles,
  canonical binding, pattern/disabled-pattern demand, world debit and failed-debit
  checkpoint retention. Clean dependency HEAD 40ff9ebfe247d56d7dd2e308e7b7eabfb61a7ce0;
  shared Lua tree hash a165c3f3262733afc1ea94a8e0ff223df004d5a753db5daecf1c93221073b4c5.
- [TESTED, offline Windows] Source preflight: core PASS, consumers PASS,
  nightfall BLOCKED with expected exit 1: required Mod ID medWorks is absent.
  The current medical source declares B47ANCEDHealthCare but preserves medWorks
  Lua APIs. No namespace/metadata aliases were invented. This is the current
  blocker; retired experienceWorks imports in the earlier medWorks snapshot are
  historical and no longer attributed to the renamed medical source.
- [VERIFIED, source snapshots] Exact API-probe and profile inventories are
  validation/0.27.0-consumers.json and validation/0.27.0-*-preflight.json. They
  fingerprint selected files/paths and record dependency HEAD/dirty state.
  Snapshot fingerprints were stable during each check. External Medical and
  Knowledge edits were observed during the task; dirty source is not a verified
  deployable pairing. Repeat source selection and fingerprints before installing.
  Water/Farming remain legacy non-Git sources; Spectrum adopts no canonical
  versions or remotes for them. All external checkouts were read-only to this task.
- [TESTED, offline Windows] Exact staged credential/path audit: 72 intended files,
  zero findings. Working/staged whitespace checks PASS.
- [VERIFIED, history/artwork] Supplied thumbnail/preview, icon, 0.25.5 audit records,
  0.26.0 feature ledger and previous change-note bytes match base history exactly.
  The original 0.26.0 validation is retained as validation/0.26.0-features.md.
- [VERIFIED, installed-source history] Steam build 25485521 was inspected for
  the prior feature iteration; full engine version remains UNKNOWN. No new
  native API guarantee or runtime result is inferred from that history.

## Exact commands and freshness

Python used: C:/Users/willi/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe.
Development dependencies are in requirements-dev.txt.

```sh
python scripts/check_versions.py --root .
python scripts/validate.py
python scripts/check_consumer_integrations.py --dependencies ..
python scripts/check_power_integration.py --dependency-root ../B47ANCEDPower
python scripts/check_test_readiness.py --dependencies .. --profile core
python scripts/check_test_readiness.py --dependencies .. --profile consumers
python scripts/check_test_readiness.py --dependencies .. --profile nightfall
python scripts/check_repository.py --staged
git diff --check
git diff --cached --check
```

The nightfall command intentionally returns 1 while its external Mod ID mismatch
exists. A blocked startup profile is not ignored or converted into PASS by the
API probe. CI runs only repository-local offline tests; it does not have the
private machine's sibling checkouts. Current package integrity/version --release
checks are deferred because no package was requested or generated.

Shared freshness command:
`Test-PZRepositoryFreshness.ps1 -Repository <explicit Spectrum repository>`.
Entry clean HEAD/upstream 7fd163b: 0/0, main ahead 4/behind 0, no unfinished operation.
Precommit REVIEW: the same ancestry, dirty only with this intended iteration.
The new branch temporarily tracks its verified base branch until first push;
no source reconciliation/reset is performed. Review includes the staged diff,
tracked files, ignored outputs and exact staged credential/path audit before push.
The PR records resulting commit, verified remote SHA and CI status.

## Runtime gates and test scope

See CONSUMER_INTEGRATIONS.md for contracts, settings, limits and ownership;
IN_GAME_TEST_HANDOFF.md for staged acceptance and the external loader blocker.
Core source preparation is complete. Full Nightfall startup remains blocked under
Spectrum-only write scope. Native laser/fixture rendering, crop sample placement,
clothing, migration, authority, treatment costs/consent in owning actions, fluid
synchronization, source streaming, late join/reconnect and restart need actual
engine evidence. No real save, external mod source or installed game was modified.
SP NOT TESTED; G7 BLOCKED / NOT TESTED; stable-release G8 BLOCKED.
No package, deploy, game/server launch, Workshop upload, stable tag or merge.
