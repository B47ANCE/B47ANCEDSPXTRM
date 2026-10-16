# B47ANCED Spectrum in-game validation

Begin stage 5 only after B47ANCEDPower is reviewed as PASS. Enable only B47ANCEDPower
and B47ANCED Spectrum (Mod ID `lightWorks`) on a disposable save.

Run `lightWorksTestStart(true)`, then `lightWorksTestChecks()` and
`lightWorksTestTour()`. The visual tour names each device in plain language,
states its expected beam, halo, color, and attachment behavior, and asks for
PASS only after the tester turns and moves with it. Results enter the durable
stage report automatically.

Use `lightWorksTestSandbox()` for a guided safe world-light setting change and
`lightWorksTestReload()` after save/reload. The report is
`%USERPROFILE%\Zomboid\Lua\theWorks Test Results - lightWorks.txt`.

For the current consumer stage, exact source preflight and known Nightfall loader
blocker, follow [IN_GAME_TEST_HANDOFF.md](IN_GAME_TEST_HANDOFF.md).
