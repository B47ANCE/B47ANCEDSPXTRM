# SPXTRM feature-pass validation

Project Version: 0.30.0

2026-10-16 (America/Phoenix). Base 5daab92e901c2f703c238f593d46c1dc3ef8907f (0.29.0).
Branch feature/spectrum-feature-completion, stacked on feature/spectrum-notifications.
Explicit pre-1.0 MINOR activation-ID transition plus additive features. Existing
Lua/save/item/sandbox/protocol identifiers remain stable; enabled-mod lists must
change to B47ANCEDSPXTRM. Prior validation is exact in validation/0.29.0-audit.md.

[TESTED, offline Windows / host Lua 5.4] 54 regression files and 59 Lua 5.1
source/template syntax files PASS. Canonical versions, identity, owned require
case, Lua-only payload, 29-language fallback/schema sets, disposable Python
preflight and credential/path checks PASS. New coverage tests calibrated model
registration/copies/readback/rollback/sync recovery; material completeness/bands;
three specialist devices/replacement restrictions/loot idempotence; timed UVC
authority/reach/power loss/repeated callbacks; canonical import identity and
bounded read-only treatment receipts. These use native object stubs, not PZ.

[TESTED, offline] Actual Power API probe includes specialist profiles and PASS.
Actual consumer API slices PASS for Nightfall aliases, Medical treatment/replay,
Water quality gates/commit/rollback and Farming unchanged observations/batches.
Health Care isolated 0.11.0 tests cover actual Spectrum interrupted-commit
receipt recovery. Exact selected source hashes, HEAD/dirty state and preflight
are recorded in validation/0.30.0-*.json. Dirty/concurrently changing dependency
snapshots are not pinned clean pairings. Full native mod bootstraps are NOT TESTED.

[VERIFIED, installed source] Steam build 25485521; full engine SemVer UNKNOWN.
Prior vanilla yaw getter/setter evidence remains current by source hash. New
device fields/native asset references were checked against generated item/model
definitions; cold-pack consumption/native complete follows ISApplyBandage and
the existing Health Care native recovery contract. SuburbsDistributions registers
OnPreDistributionMerge; MedicalStorageTools/GardenStoreTools are actual lists.
Source inspection does not prove native parsing, timing, rendering or transport.
No game source/assets/classes are copied or executed.

[VERIFIED, history] Owner thumbnail/icon bytes remain unchanged after the authoring
root move. Spectrum lettering in supplied artwork is retained. Historical Contents,
packages, upload state, validation/changenotes and Water/Farming source are unchanged.
GitHub repository ID 1421935901 remains public, now B47ANCE/B47ANCEDSPXTRM. Four
developer workspace path references were updated; installed managed settings and
credentials were untouched. Health Care artwork checkout was not edited. Nightfall
reconciled to public main containing effigy and audit/CI before the dependency change.

Commands (bundled Python 3.12 and requirements-dev.txt):

```text
python scripts/check_versions.py
python scripts/validate.py
python scripts/check_power_integration.py --dependency-root ../B47ANCEDPower
python scripts/check_consumer_integrations.py --dependencies .. --medical-root ../.worktrees/healthcare-spectrum-treatment
python scripts/check_test_readiness.py --dependencies .. --profile core
python scripts/check_test_readiness.py --dependencies .. --profile nightfall --medical-root ../.worktrees/healthcare-spectrum-treatment
python scripts/check_test_readiness.py --dependencies .. --profile consumers --medical-root ../.worktrees/healthcare-spectrum-treatment
python scripts/check_repository.py --staged
git diff --check
git diff --cached --check
```

Startup/precommit: Test-PZRepositoryFreshness.ps1 against each explicit repository.
Exact commit/push/CI results belong to the iteration report, not this precommit record.

[RUNTIME GATE] Native built-in model calibration, blood/FBO/depth and additional
overlay assets remain incomplete. Crop growth is deferred while Farming stays
unchanged. Native shared-action timing/reference serialization, real items/fluids,
renderer/depth, controllers, save/reload, joins/restarts and dedicated acceptance
are NOT TESTED. G7 BLOCKED / NOT TESTED; stable G8 BLOCKED. Current Knowledge source
also reports an upstream dedicated-storage blocker; source-contract PASS does not
override it. No packaging, deployment, game/server launch or Workshop upload.
