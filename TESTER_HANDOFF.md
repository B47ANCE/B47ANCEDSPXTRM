# B47ANCED Spectrum 0.28.0 playtester handoff

Begin only after B47ANCEDPower is reviewed as PASS. Enable only B47ANCEDPower and
B47ANCED Spectrum (Mod ID `lightWorks`) on a disposable save and run `lightWorksTestStart(true)`.

1. Run `lightWorksTestChecks()` to prepare the kit and verify core behavior.
2. Run `lightWorksTestTour()`. Move and turn with each named light. Enter PASS only when the described beam, halo, color, and attachment behavior is visible.
3. Use **Light Pattern** on handheld and weapon lights. Verify selections persist and low-charge lights flicker naturally.
4. Drop active white, colored, and UV lights. Verify illumination follows the item; controls, aiming, drain, pickup, and exhaustion clean up correctly.
5. Save/quit/reload a configured light. Confirm its bulb, charge, pattern, and direction, then run `lightWorksTestReload()`.
6. Run `lightWorksTestSandbox()` and follow its world-light setting instructions.
7. Mark hosted/dedicated testing BLOCKED until actually performed.
8. Run `lightWorksTestReport()`.

Return the stage report, `console.txt`, and screenshots for visual failures. Do
not enable Nightfall until this stage is reviewed.

This iteration fixes the nine audit defects in source. Follow `docs/AUDIT_FIXES.md` for dedicated checks; host regressions alone do not establish a stage PASS.


Additional 0.26.0 tests: arbitrary facing before/after walking to a world light;
thin-wall beam boundaries; two-client remote light/reconnect; wall-clock flicker
at different game speeds; Base.Laser while aiming with mouse/controller and
split-screen; custom fixture power/off/remove; clothing layers/holes and unknown
protection; known/empty/conflicting legacy fixtures through restart/late join.
Use disposable migration fixtures, never real saves. Update all clients/server.
See docs/FEATURE_COMPLETION.md and docs/VALIDATION.md for blockers.

Current consumer stage: follow docs/IN_GAME_TEST_HANDOFF.md. Core and refreshed Nightfall source preflights
pass; actual loader/runtime behavior is still NOT TESTED. Optional
consumer helpers report API presence only. No deployment or runtime test has run.

0.28.0: compare single-crop and LWIntegrationCropLightingBatch output on a small
field. Test walls, on/off, incomplete samples, paging and unchanged crop state.
Use docs/AUDIT_0_28_0.md for the three defect reproductions and acceptance.
