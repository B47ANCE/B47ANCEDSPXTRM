# Remaining audit work: closure and blocked gates

Project Version: 0.29.0

Baseline: a2a018393c417c5e29dfda6153266c65b0e5da41 (0.28.0).
This ledger answers the remaining work from AUDIT_0_28_0.md without relabeling
historical tests or claiming runtime completion from source checks.

| Remaining item | Current disposition | Evidence / next required action |
| --- | --- | --- |
| L8 notification ownership/lifecycle | Implemented and offline tested | Version-1 process-local advisory bus; bounded registrations/FIFO dispatch, copied payloads, explicit teardown, listener diagnostics and post-commit producers. See CONSUMER_NOTIFICATIONS.md. |
| L8 queries / source scan cost | Implemented in 0.28.0; regressions retained | Single-capture clustered exposure and paged crops; no growth mutation or cached treatment evidence. |
| Read-only observation integrity | Corrected | Sunburn getState no longer creates missing replay history in a saved record. Malformed/future histories remain untouched and rejected. |
| Debug fixture authority | Hardened | All development helpers require confirmed debug mode. Mutating kit/API/tour helpers refuse multiplayer/server contexts before inventory access; ordinary validated gameplay actions are unchanged. |
| Native world-model rotation route | Lua call route verified; production alignment BLOCKED | Installed vanilla setters/getters and native float descriptors recorded. SP-only preview/restore probe implemented. Need real per-model alignment/render-refresh evidence; no default mapping is guessed. |
| Native blood/FBO redraw | BLOCKED / NOT TESTED | Native declaration is not Lua/depth proof. Existing guarded diagnostic spike retained; actual render-order/occlusion evidence required. No Java fallback. |
| Dedicated authority, persistence and late join | BLOCKED / NOT TESTED | Existing state owners and replay/sync tests pass offline; run two-client, restart, streaming and recovery acceptance in PZ. |
| Native inventory/fluids, lasers, clothing, controllers/split-screen | BLOCKED / NOT TESTED | Concrete acceptance in TESTING.md and IN_GAME_TEST_HANDOFF.md. Current source/API probes cannot prove these. |
| Nightfall / Medical / Water / Farming source integration | Spectrum adapters complete; source profiles pass | Exact dependency snapshots retained. Consumer domain effects/content remain owned by those projects, which the user kept read-only. |
| Extra fixture/device/item/overlay content | Outside current authorized definition/asset scope | No unsupported IDs, devices, biological tuning, growth behavior or assets are invented. Existing generic providers are implemented. |
| Sunburn timing calibration | Configurable and provisional | Measure in-game with clothing/unknown protection and server sandbox settings; source math is not runtime calibration. |
| Stable release | G8 BLOCKED | G7 dedicated evidence required; no package, deploy, upload or stable tag authorized/performed. |

All remaining implementable Spectrum source work identified by this targeted
audit is implemented and tested offline. The overall audit is NOT fully closed:
engine/runtime evidence and explicit external-scope/content decisions remain.
This is not a claim that every possible roadmap feature or every mod interaction
has been exhaustively implemented or audited.

No game/server launch, real-save mutation, deployment, other-mod write, Workshop
upload, Steam restart or cleanup was performed. The next dependent step is an
explicitly authorized installation of a reviewed, matching source pairing, followed
by actual human-observed SP and dedicated acceptance. Deployment itself is not
runtime PASS, and missing observations must remain BLOCKED rather than waived.
