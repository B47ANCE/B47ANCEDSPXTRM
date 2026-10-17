# Remaining-audit source validation

Project Version: 0.29.0

Date: 2026-10-16 (America/Phoenix).
Base: a2a018393c417c5e29dfda6153266c65b0e5da41 (0.28.0).
Branch: feature/spectrum-notifications; stacked PR base: feature/spectrum-batched-queries.
MINOR: advisory notification API plus observation/debug hardening and SP probe.

## Current source/offline evidence

- [TESTED, offline Windows] python scripts/validate.py: 48 host Lua 5.4 regression
  files, 51 Lua 5.1 source/template syntax files, disposable Python preflight,
  canonical version, identity, Lua-only, owned require case, 29-language/schema
  fallback and credential/path checks PASS (242 selected files, no findings).
  Host Lua is not PZ/Kahlua and source signatures are not runtime proof.
- [TESTED, offline Windows] Advisory bus: independent snapshots, invalid payload
  rejection, deterministic subscribe order, unsubscribe/replacement tokens,
  listener exceptions/unprintable errors, bounded reentrant FIFO, registration/
  delivery budgets and recovery after exhaustion. Observer facade has no producer
  helpers. Events are not networked, persisted, replayed or accepted as intents.
- [TESTED, offline Windows] Commit coverage: pattern/orientation replay/client
  refusal, migration receipt idempotence, Medical/Sunburn dose receipts, service
  rollback/uncertain silence and cleared recovery marker before notification.
  Depletion requests existing semantic/native synchronization before callbacks.
  Low-level service building blocks intentionally emit no transient events.
- [TESTED, offline Windows] Sunburn getState preserves a missing history field in
  a valid old record; malformed false/string/future histories remain untouched and
  rejected. Only a valid authoritative mutation may create missing history.
- [TESTED, offline Windows] Confirmed-debug/SP-only native yaw probe: readback,
  original restore, setter failure after write, failed restore quarantine, exact
  backing removal and unchanged logical orientation. No real native setter/game
  execution occurred. All manual fixture-mutating helpers refuse multiplayer
  before inventory access and missing-debug helper modules remain inert.
- [TESTED, offline Windows] Actual consumer API slices PASS against current paired
  source: Nightfall registration/aliases, Medical treatment/replay, Water quality
  transaction/rollback, Farming single/batched observations. Native objects are
  stubs; full mod bootstraps were not loaded. Exact identities/hashes/HEAD/dirty
  state: validation/0.29.0-consumers.json. All external mods were read-only.
- [TESTED, offline Windows] core/nightfall/consumers source preflights PASS:
  validation/0.29.0-*-preflight.json. Each snapshot is stable during its own check;
  it is not a verified installed/deployed pairing. Dirty dependency source must be
  pinned and reviewed before installation. Prior-version snapshots stay historical.
- [TESTED, offline Windows] Actual B47ANCEDPower integration probe PASS against
  clean 40ff9ebfe247d56d7dd2e308e7b7eabfb61a7ce0. Shared Lua tree SHA-256:
  a165c3f3262733afc1ea94a8e0ff223df004d5a753db5daecf1c93221073b4c5.
- [VERIFIED, installed vanilla source] InventoryItem world-yaw getters/setters are
  observed in vanilla drop/placement Lua. Steam build 25485521; full engine version
  UNKNOWN. Native metadata confirms float descriptors, without proving runtime
  alignment/render refresh/sync. IsoSprite.renderBloodSplat is native-only evidence,
  explicitly UNKNOWN for Lua invocation/depth. Portable entries are retained in
  validation/api-evidence-25485521.json and class metadata/digests in
  validation/native-metadata-25485521.json. The three API records validate and were
  recorded using the installed pz-api-audit helper in the unmanaged local draft.
- [TESTED, offline Windows] Exact staged credential/path audit: 53 intended
  files, zero findings. Working/staged whitespace checks PASS.
- [VERIFIED, history] Exact owner thumbnail/preview/icon, 0.28.0 audit, historical
  probe snapshots and previous changenote bytes preserved. The prior validation
  is copied exactly to validation/0.28.0-audit.md rather than relabeled current.

## Exact commands and freshness

Python used: C:/Users/willi/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe.
Dependencies: requirements-dev.txt. Engine metadata inspection uses only Python
standard-library reads, never executes/extracts/builds game or custom Java code.

```sh
python scripts/check_versions.py --root .
python scripts/validate.py
python scripts/check_consumer_integrations.py --dependencies ..
python scripts/check_power_integration.py --dependency-root ../B47ANCEDPower
python scripts/check_test_readiness.py --dependencies .. --profile core
python scripts/check_test_readiness.py --dependencies .. --profile nightfall
python scripts/check_test_readiness.py --dependencies .. --profile consumers
python scripts/inspect_native_metadata.py --game-root <verified-game-root>
python <pz-api-audit-skill>/scripts/api_library.py validate --library docs/validation/api-evidence-25485521.json
python scripts/check_repository.py --staged
git diff --check
git diff --cached --check
```

Shared freshness: Test-PZRepositoryFreshness.ps1 -Repository <explicit Spectrum
repository>. Entry: clean HEAD/upstream a2a0183, 0/0; main ahead 6, behind 0;
no unfinished operations. Named branch starts from that verified commit and
tracks its base until first push. Precommit dirty REVIEW must contain only this
iteration. Exact staged changes, tracked paths and ignored outputs are reviewed
and credential-audited before the public push. Resulting commit/remote SHA and CI
outcome are reported with the stacked PR. No main merge or stable tag requested.

## Closure limits and next dependent action

AUDIT_CLOSURE.md is the authoritative remaining-work matrix. Notifications source
and lifecycle contract, observation integrity, debug fixture authority, native
setter evidence and a manual SP probe are implemented. No new gameplay setting,
state schema, network authority, production model mapping, blood shader, domain
content or cross-mod file write is introduced. Event/page/queue/probe caps are
technical limits; existing meaningful settings remain server authoritative.

Native model alignment and blood/FBO/depth need actual disposable PZ evidence.
Inventory/fluids, rendering, clothing, controllers/split-screen, dedicated native
APIs, streaming, late join, reconnect and restart remain runtime gates. Human
observation cannot be replaced by more source tests. Consumer-owned gameplay
content stays outside the user-selected read-only scope. See CONSUMER_NOTIFICATIONS.md,
NATIVE_PRESENTATION_GATES.md and IN_GAME_TEST_HANDOFF.md for exact acceptance.

SP NOT TESTED; dedicated G7 BLOCKED / NOT TESTED; stable-release G8 BLOCKED.
No package, deployment, game/server launch, real-save change, Workshop upload,
Steam restart, external-mod write, merge, stable tag or artifact cleanup.
