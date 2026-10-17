# B47ANCED Spectrum Testing

Record the exact installed Build 42 version (minimum declared: 42.20.3) and
inspect `console.txt` afterward. The full current engine version is UNKNOWN.

External playtesters should use [IN_GAME_TESTING.md](IN_GAME_TESTING.md) and
`lightWorksTestStart(true)`. The `LW*` commands remain available for focused
developer investigation; mocked execution is not an in-game PASS.

1. Run `LWStartReleaseSuite()`. It performs the API, servicing, UV-semantic, and available B47ANCEDPower battery checks, then starts the visual tour.
2. Inspect each equipped light, enter `PASS` or describe the issue, and continue; every report is written to `console.txt`.
3. Confirm metadata, version `0.29.0`, B47ANCED Spectrum sandbox page, and error-free load.
4. Right-click supported, unsupported, nested, equipped, attached, and weapon-part lights.
5. Confirm bulb actions share the light's existing submenu and show correct icons.
6. Install, remove, and replace every bulb with and without required tools; verify no loss or duplication.
7. Confirm colored and UV bulbs tint emitted light only—not the inventory icon or world model. If a beam is white, run `LWColorProbe()` before changing equipment.
8. Verify straight belt lights create a local halo, left/right angle lights point outward, and Heavy-Duty lights cannot attach.
9. Compare emitter footprints: Penlight < regular Flashlight < Heavy-Duty range/strength; weapon light narrow; lantern radial. Confirm bulb multipliers preserve these relative differences.
10. Verify red-light visibility semantics, burnout, save persistence, and attachment slots.
11. Install a Gun Light on a held firearm, activate it, install red and UV bulbs, and verify both colored beams. Run `LWColorProbe()` while the weapon light is on and confirm it reports `item=<weapon> emitter=Base.GunLight`.
12. Verify gun-light and military/police spawn distributions, including Army 80% red / 20% white.
13. Confirm an unpatched mod light enters only the review queue and never breaks the context menu.
14. Confirm an exact verified patch enables servicing and, with Nightfall, accepts UV bulbs.
15. Test single-player, hosted multiplayer, and dedicated server separately before making compatibility claims.
16. Confirm the game rejects an incomplete family installation missing B47ANCEDPower, then verify sized cells appear inside each registered light's own item menu with the complete family.
17. Confirm verified mod lights inherit B47ANCEDPower support and Nightfall UV bulbs apply their registered consumption multipliers.
18. Drain each portable/weapon UV light to zero and quarantine one development
    fixture. Neither may remain in `collectPlayerEmitters`; restoring verified
    positive charge must restore emission. Confirm attached-item wrappers resolve
    to their actual inventory item and only active weapon lights emit UV.
19. With provisional defaults, verify unprotected peak sunlight begins producing
    severity after roughly 45 in-game minutes, reaches maximum near four hours,
    recovers only while sheltered, persists across save/reload, and ignores
    artificial UV. Repeat with a development protection provider and medWorks
    treatment operation; confirm duplicate treatment IDs are rejected.
20. Drain handheld, belt, and weapon-mounted lights below 10% charge. Confirm
    each begins deterministic real-time flickering, flickers more strongly near
    empty, stops emitting at zero, and returns to steady output above the
    configured threshold without changing activation or accelerating drain.
21. Exercise steady, strobe, pulse, beacon, SOS, alternating, and emergency
    patterns on handheld and weapon lights. Confirm save persistence, opposite
    alternating phases, obstruction safety, and B47ANCEDPower average duty-cycle
    drain after each authoritative pattern change.
22. Confirm **Light Pattern** appears inside each registered light's existing
    item submenu and marks the current selection. In hosted play, verify stale
    or unowned item IDs do nothing and a valid choice replicates without menu
    duplication.
23. Turn on registered white, colored, and UV portable lights and drop them.
    Confirm each emits at its world position and UV uses RGB `0, 0, 255`.
    Run `LWWorldEmitterStatus()` and verify one bound record per physical light,
    correct RGB/radius/UV values, and no `COLOR DESYNC`. Pick up, switch off,
    exhaust, move, save/reload, and revisit them; no stale or duplicate halo may
    remain. `LWWorldEmitterRescan()` forces a bounded nearby reconciliation.
24. Disable **Enable dropped and placed world lights** and confirm world
    emitters are cleaned up without changing carried-light behavior.
25. Right-click a nearby dropped light and use **Turn On/Turn Off**. Confirm the
    player walks adjacent and completes the timed interaction; empty, bulbless,
    and burned-out lights must reject activation. In hosted play, attempt the
    interaction from another client and verify both clients converge on one
    server-owned state with no ghost source.
26. Right-click a nearby dropped directional light, open **Aim Light**, and test
    north, east, south, and west. Confirm the visible beam and artificial-UV cone
    rotate together, persist after save/reload, and replicate to another client;
    radial lanterns must not expose the aiming menu.
27. Put an active dropped UV light inside an Alpha den and trigger light defense.
    Confirm the assigned infected paths to and physically thumps the visible
    world item until vanilla removes it. The visible source and semantic UV must
    then disappear. Turning the light off or exhausting it must withdraw it from
    defense targeting without deleting the item.

Export discovery evidence with `LWExportLightReview()`.

## 0.15.8 UV input isolation

Register a development exposure modifier returning NaN and provide malformed
third-party emitters with missing/throwing coordinates, zero range, infinite
intensity and invalid spectra. They must contribute nothing without suppressing
valid sources. World scans are integer-radius bounded, object/attachment/weapon
collections are capped, and invalid scan centers return empty results.

Offline commands and current evidence: [VALIDATION.md](VALIDATION.md). The name changed; technical IDs and `LW*`/`lightWorksTest*` commands remain stable.


## Nine-defect regression and multiplayer plan

Run `python scripts/validate.py`; the new/extended tests are mapped in
[AUDIT_FIXES.md](AUDIT_FIXES.md). Host tests simulate authority and inventory;
they are not PZ runtime evidence. Use that document's dedicated plan to check
burnout, first/repeated drops, switch-off settlement, failure/retry, reconnect IDs,
disabled patterns, unknown sunlight, bulb removal and renderer disable/re-enable.


## Feature completion acceptance

1. Run `python scripts/validate.py`. For actual Power source pairing, run
   `python scripts/check_power_integration.py --dependency-root <verified-power-repository>`.
   Record its HEAD, dirty status and source-tree fingerprint; it is offline only.
2. Use matching client/server source and B47ANCEDPower on disposable saves. Aim
   world lights at 27.5/135/359 degrees, cardinal directions and across thin walls.
   Confirm visible/UV geometry, persistence, replay rejection, same-floor/distance
   checks, pickup/drop and late-join convergence.
3. Verify remote colored handheld/attached/weapon lights, client disconnect,
   suppression restoration, clock skew and real-ms flicker at several game speeds.
4. Aim Base.Laser on a valid mounted weapon. Check dot and optional beam at walls,
   doors/windows, unloaded cells, zoom, split-screen and controllers. It must not
   change accuracy, damage, ammo, charge or native activation.
5. Register a disposable fixture provider; test known on/off/power, UV attribution,
   invalid geometry, custom renderer opt-in, duplicate discovery, removal and streaming.
6. Check sunburn status after known samples, intact/holed/layered clothing, disabled
   coverage and failed protection APIs. Unknown intervals cannot heal or advance dose.
7. Test legacy known/empty/burned/conflicting/unknown fixtures in carried nested
   inventory, attachments, weapon parts and streamed world lights. Confirm originals,
   receipt, wear and no duplicate output across restart. Simulate active/unknown
   Bulbworks runtime and unresolved aliases: preserve/quarantine, never guess.
8. Validate native zombie thump/removal with Nightfall's own authoritative behavior,
   then reload/rejoin/restart. No client may apply physical destruction directly.

All items above remain runtime NOT TESTED until evidence is recorded; G7 and stable
G8 remain BLOCKED. Native blood redraw/model rotation and consumer-specific actions
retain the historical native blockers in FEATURE_COMPLETION.md. Current consumer
contracts and the Nightfall loader blocker are in CONSUMER_INTEGRATIONS.md.

## Current consumer stage

Follow [IN_GAME_TEST_HANDOFF.md](IN_GAME_TEST_HANDOFF.md), including source
preflight, disabled-by-default UVC tests, both bulb aliases, Medical procedure
replay, crop immutability and two-client/restart acceptance. Debug status is not
a runtime PASS. New regressions: test_consumer_aliases.lua, test_consumer_bridges.lua,
test_consumer_exposure.lua, test_integration_harness.lua and test_readiness.py.

## Batch queries and audit regressions

Run python scripts/validate.py. New tests test_batched_exposure.lua and
test_crop_batches.lua cover one-scan parity, independent walls, dynamic on/off,
output isolation, bounded paging and partial/invalid input. test_debug_guard.lua,
test_fixtures.lua and test_lasers.lua reproduce the three audited defects; the
prototype test also verifies SP-only diagnostic sample placement.

In PZ debug mode, provide a small array of actual native crops to
LWIntegrationCropLightingBatch(crops, {cursor=0,limit=16}). Compare every successful
observation with LWIntegrationCropLighting(crop), then alter power/cone/obstruction.
Check ok and observation.complete separately. Continue through nextCursor; invalid
or overly wide pages must report failures, never fabricate known darkness. Test
streamed/unloaded squares and 32-target/source-budget cases; confirm crop growth,
health and water never change. No automatic growth or treatment action is added.

## Notifications and native-presentation gates

Run python scripts/validate.py. New notification tests cover independent payloads,
subscription teardown/replacement tokens, callback errors/unprintable errors,
64-listener/128-event limits, nested dispatch and post-commit publication. Service
rollback/uncertainty stays silent; depletion requests existing native/semantic sync
before notification. Native tests use stubs, not game rendering.

In an actual SP and dedicated pairing, subscribe with a namespaced ID, query the
initial owner state, perform validated UI actions and compare each notification
with committed state. Reject/replay/rollback operations must not emit normal
success. Teardown with its token, reconnect/restart, reattach/query again; no past
event or native object reference may replay. Confirm the client has a separate bus
and receives state through existing synchronization. No listener may award items
or apply effects from an event alone. Inspect status for failure/drop counts.

Use NATIVE_PRESENTATION_GATES.md for the SP-only yaw readback/restore and native
blood FBO scenarios. All kit/API/tour fixture mutations are now SP-only; MP tests
use authorized server-admin fixture preparation and normal validated gameplay
actions, not the mutating local kit helpers. No deployment or launch is automatic.
