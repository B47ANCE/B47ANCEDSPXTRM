# Spectrum development test handoff

Project Version: 0.29.0

Core Spectrum + B47ANCEDPower, Nightfall and optional-consumer source preflights
pass against the recorded current checkouts. The earlier medWorks loader mismatch
is corrected in Nightfall 0.29.0 metadata, which now requires B47ANCEDHealthCare.
No source preflight proves actual native loading, installation or runtime behavior.
Some dependencies are dirty; review and pin matching copies before any explicitly
authorized deployment. No package, deployment, game/server launch or upload was
performed by this iteration. All consumer folders remain read-only to this task.

## Before installing

Use matching server/client source and disposable saves. Confirm the installed
Build 42 version meets the declared minimum 42.20.3; Steam build 25485521 was
inspected previously, but full engine version and runtime behavior are UNKNOWN.
Do not infer the exact version from versionMin. Record all enabled Mod IDs,
versions, source hashes, deployment hashes, engine version and console errors.

```sh
python scripts/validate.py
python scripts/check_power_integration.py --dependency-root ../B47ANCEDPower
python scripts/check_consumer_integrations.py --dependencies ..
python scripts/check_test_readiness.py --dependencies .. --profile core
python scripts/check_test_readiness.py --dependencies .. --profile nightfall
python scripts/check_test_readiness.py --dependencies .. --profile consumers
```

The layouts are explicit in scripts/consumer_sources.py. Missing or changed source
must fail, not silently fall back to stale Contents. The Water/Farming Contents
roots are their evidenced authoritative sources; Spectrum's Contents is stale.
The current consumer-only profile can pass without Nightfall, using
B47ANCEDHealthCare, ProjectMORTIS, B47ANCEDKnowledgeAndWisdom, B47ANCEDPower,
lightWorks, waterWorks and farmWorks. Dirty dependency worktrees require owner
review and pinned matching installation before testing. Source PASS is not a
release, package-integrity, installation or native loader PASS.

## Single-player core stage

1. After deployment is separately authorized and verified, enable B47ANCEDPower
   and lightWorks only on a fresh disposable save. Inspect errors before starting.
2. Run lightWorksTestStart(true), lightWorksTestChecks(), lightWorksTestTour(),
   lightWorksTestSandbox(), then lightWorksTestReport(). Record visible behavior
   honestly; the helpers cannot certify their own visual expectations.
3. Follow TESTING.md for servicing, drain/retry, patterns, arbitrary aiming,
   remote rendering, laser walls/windows, clothing holes, native thumping,
   pickup/drop, streaming, reload and legacy migration scenarios.
4. Debug mode exposes LWIntegrationStatus(). It reports API presence, not runtime
   acceptance. LWIntegrationKit() manually creates the existing SP test kit plus
   registered canonical Nightfall bulbs; it refuses multiplayer clients.

## Optional integration stage

- Nightfall: rerun preflight and verify the installed matching dependency IDs. Confirm both
  canonical bulb profiles, power loads, AVAILABLE alias status and expected UVA
  semantics. Make only disposable held-light legacy fixtures. Test each old ID
  in installed and last-burned fields with wear, then run
  LWIntegrationMigrateHeld(). Originals and one receipt must survive reload;
  repeated calls add no bulb/output. Test missing profiles, conflicts, client
  refusal, active Bulbworks and unknown records: preserve/quarantine them.
- Medical: through an authorized server gameplay action, call treatSunburn with
  the exact patient, amount, unique operation and action source. Confirm reduced
  dose, unchanged ownership, lock conflicts, repeated-ID refusal, malformed ID
  rejection, reconnect and persistence. No consumable/consent UI was added by
  Spectrum; the calling action must enforce those requirements.
- Water: integration defaults off. Confirm refusal while disabled, with ordinary
  Nightfall UVA bulbs, mixed/non-water/empty containers, unknown position/path,
  glass, high turbidity and insufficient UVC. For a positive disposable fixture,
  use an explicit powered/on UVC provider through API.Fixtures.register, then
  enable the server sandbox opt-in. Invoke treatWater from a trusted server
  action. Verify only biological quality changes, one Water history entry,
  repeated-ID refusal, write failure/rollback, uncertain recovery, reload and
  native taint/quality replication. There is no shipped UVC device or timed
  disinfection gameplay action; do not claim sterilization or completed hardware.
- Farming: LWIntegrationCropLighting(nativeCrop) reads a supplied compatible crop.
  Compare light on/off, cone, wall/window, darkness/unknown sunlight and source
  budget cases. LWIntegrationCropLightingBatch(crops, options) adds bounded pages: compare
  with individual observations, check completeness, nextCursor and rejected input
  indices, then test 32 targets and too-wide/multiple-floor clusters. A successful
  page uses one source capture, with no retained cross-call cache. Crop
  water/growth/health must stay unchanged. These helpers report
  normalized observations only; there is no growth effect or new farming UI.

## Remaining audit acceptance

Follow CONSUMER_NOTIFICATIONS.md for subscription IDs/tokens and exact producer
scope. Test successful state, duplicates, rollback, callback failures, late attach,
teardown and separate client/server Lua VMs. Requery on attach/restart; never use
notifications as an authority or reward trigger. Status must expose failures/drops.

Follow NATIVE_PRESENTATION_GATES.md for manual debug/SP world-model previews and
restoration. Use a disposable placed light, record original/native/logical angles,
verify rollback/removal and save backup. Native setter readback is not a visible
alignment PASS. The blood spike still needs actual FBO/depth evidence; no Java
fallback or production native redraw is introduced. Helpers that spawn or mutate
fixtures are SP-only; use authorized server-admin tools to prepare MP fixtures.

The closure matrix AUDIT_CLOSURE.md retains all unobserved runtime gates. No
other-mod writes or new domain gameplay content were authorized by this iteration.

## Dedicated authority stage

Use two clients with the same explicitly selected source set. Only the server may
migrate records or commit treatment/quality state. Exercise invalid/unowned intent
through the owning action's validated entry point, duplicate operations, concurrent
requests/locks, late join, disconnect/rejoin, streamed objects and full dedicated
restart. Confirm no duplicate output, stale illumination, hidden client healing,
fluid divergence or lost recovery journals. Repeat vanilla native APIs on the
actual headless server; host stubs and SP do not prove those contracts.

Return the stage report, versioned source/deployment inventory, console errors,
reproduction steps, and screenshots for visual failures. Keep private logs and
player data out of public Git. G7 BLOCKED / NOT TESTED and stable G8 BLOCKED until
observed dedicated evidence is reviewed. No stable tag or release is implied.
