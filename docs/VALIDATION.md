# Audit and batch-query iteration validation

Project Version: 0.28.0

Date: 2026-10-16 (America/Phoenix).
Base: 79775cdfa2577df7f90c77dc03ccc63323fe46f5 (0.27.0).
Branch: feature/spectrum-batched-queries. PR base: feature/spectrum-consumers.
Classification: MINOR, additive read-only batch exposure/crop queries plus fixes.

## Current evidence

- [TESTED, offline Windows host Lua 5.4] Three regression assertions fail against
  baseline production and pass after fixes: missing-debug-API hook registration,
  mutable fixture definition and finite laser magnitude overflow. Before-fix
  scripts/test_lua.py: 42 files, exactly those three failures. Reproductions,
  priority, scope, causes and acceptance are in AUDIT_0_28_0.md.
- [TESTED, offline Windows] python scripts/validate.py PASS: 44 host Lua 5.4
  regression files, 49 Lua 5.1 source/template syntax files, disposable Python
  preflight test, canonical versions, identity, Lua-only, require-path case,
  29-language fallback/schema checks and repository credential/path scan
  (225 selected files, zero findings). No source/test tool is a PZ runtime test.
- [TESTED, offline Windows] New batch coverage: shared capture for 32 points,
  exact single/batch parity including per-target scope boundaries, independent
  walls, dynamic on/off state, detached output tables, input/page budgets,
  span/floor rejection before discovery, partial-source incompleteness, stable
  page indices, unknown/absent Farming rejection and unchanged crop state.
  Existing Water, Medical, migration, rendering and authority regressions pass.
- [TESTED, offline Windows] Actual-source consumer probe PASS: Nightfall bulb
  registration/aliases, Medical treatment/replay, Water refusal/transaction/rollback
  and Farming single/two-crop batch parity. Native objects are stubs; complete mod
  bootstraps were not loaded. Exact paired source inventory/fingerprints and
  HEAD/dirty states are in validation/0.28.0-consumers.json. One preceding probe
  was invalidated when an external source changed during execution; later stable
  probes passed. Some dependencies are dirty; repeat pinning/fingerprints before
  installation rather than treating their HEAD alone as the observed source.
- [TESTED, offline Windows] Source preflights core, nightfall, consumers PASS.
  Current Nightfall 0.29.0 metadata now requires B47ANCEDHealthCare (0.10.0),
  closing the prior external Mod ID mismatch. Current snapshots are
  validation/0.28.0-*-preflight.json. These are source checks, not native loader
  or dependency runtime validation. Consumer folders were read-only to this task.
- [TESTED, offline Windows] Actual B47ANCEDPower integration probe PASS against
  clean HEAD 40ff9ebfe247d56d7dd2e308e7b7eabfb61a7ce0. Shared Lua tree SHA-256:
  a165c3f3262733afc1ea94a8e0ff223df004d5a753db5daecf1c93221073b4c5.
- [TESTED, offline Windows] Exact staged credential/path audit: 40 intended
  files, zero findings; working/staged whitespace checks PASS.
- [VERIFIED, history] Thumbnail, preview, icon, prior audit/feature records and
  0.27.0 snapshots match exact base bytes. Previous changenote remains an exact
  suffix. Original 0.27.0 validation is preserved as validation/0.27.0-integrations.md;
  it retains its original BLOCKED result rather than being relabeled as current.
- [VERIFIED, installed source] Steam manifest build remains 25485521; full engine
  version UNKNOWN. Existing vanilla FishingUtils.lua uses getAimVector(Vector2)
  and reads its returned getX/getY (lines 89-92). No new native symbol or render
  hook is introduced; batch queries reuse existing grid/occlusion APIs. Prior
  class/source fingerprints remain historical, not refreshed runtime proof.

## Exact commands

Python executable used:
C:/Users/willi/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe.
Dependencies: requirements-dev.txt.

```sh
python scripts/check_versions.py --root .
python scripts/validate.py
python scripts/check_consumer_integrations.py --dependencies ..
python scripts/check_power_integration.py --dependency-root ../B47ANCEDPower
python scripts/check_test_readiness.py --dependencies .. --profile core
python scripts/check_test_readiness.py --dependencies .. --profile nightfall
python scripts/check_test_readiness.py --dependencies .. --profile consumers
python scripts/check_repository.py --staged
git diff --check
git diff --cached --check
```

Freshness command: Test-PZRepositoryFreshness.ps1 -Repository <explicit Spectrum
repository>. On entry: clean HEAD/upstream 79775cd, ahead/behind 0/0; main ahead 5,
behind 0, no unfinished operations. Named branch starts from that verified commit;
it temporarily tracks the verified base until first push. Dirty precommit REVIEW
is interpreted against only this iteration's intended changes. Exact staged diff,
tracked files and ignored outputs are reviewed and credential-audited before push.
Commit/remote SHA and CI outcome are reported with the PR; no main merge or tag.

## Limits and runtime gates

No new gameplay state, networking, persistent schema or meaningful gameplay
setting. Batch/page/scan caps are internal resource limits; Water still samples
fresh optical facts on the authority. Fixture callbacks retain live owner state,
while changing a registration now requires unregister/register. The debug native
blood prototype remains a gated experiment; its guard fix does not complete FBO
rendering or verify Lua native redraw. New manual sample placement is SP-only.

Next acceptance: actual native crop arrays; compare single/page output across
lights, walls/glass, source budgets and unloaded squares; verify no growth/water
changes; repeat with client/server matching source and late join/restart. Review
laser rendering, native power/fluids/inventory, clothing, save/streaming and MP
synchronization separately. Native shaders/model rotation and consumer-specific
Medical/Water actions or growth effects remain outside this completed query slice.

SP NOT TESTED; dedicated G7 BLOCKED / NOT TESTED; stable-release G8 BLOCKED.
No package, --release artifact check, deploy, game/server launch, Workshop upload,
Steam restart, merge or stable tag. See IN_GAME_TEST_HANDOFF.md for acceptance.
