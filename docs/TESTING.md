# B47ANCED Spectrum Testing

Test on Project Zomboid Build 42.20.3 and inspect `console.txt` afterward.

External playtesters should use [IN_GAME_TESTING.md](IN_GAME_TESTING.md) and
`lightWorksTestStart(true)`. The `LW*` commands remain available for focused
developer investigation; mocked execution is not an in-game PASS.

1. Run `LWStartReleaseSuite()`. It performs the API, servicing, UV-semantic, and available powerWorks battery checks, then starts the visual tour.
2. Inspect each equipped light, enter `PASS` or describe the issue, and continue; every report is written to `console.txt`.
3. Confirm metadata, version `0.25.4`, B47ANCED Spectrum sandbox page, and error-free load.
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
16. Confirm the game rejects an incomplete family installation missing powerWorks, then verify sized cells appear inside each registered light's own item menu with the complete family.
17. Confirm verified mod lights inherit powerWorks support and Nightfall UV bulbs apply their registered consumption multipliers.
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
    alternating phases, obstruction safety, and powerWorks average duty-cycle
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
