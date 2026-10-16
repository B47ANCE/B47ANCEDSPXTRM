# B47ANCED Spectrum 0.25.4 playtester handoff

Begin only after powerWorks is reviewed as PASS. Enable only powerWorks and
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
