# Spectrum audit and next roadmap slice

Project Version: 0.28.0

Date: 2026-10-16. Audited baseline: 79775cdfa2577df7f90c77dc03ccc63323fe46f5
(0.27.0). Compatibility: MINOR, additive read-only query APIs plus targeted fixes.

## Scope and evidence

[VERIFIED, source] Reviewed current metadata/version mirrors, roadmap, bootstraps,
fixture registration/presentation, laser geometry/presentation, UV/occlusion,
consumer exposure and treatment delegation, clothing protection, debug helpers,
source preflight and existing authority/persistence regressions. This is a targeted
source/offline audit, not an exhaustive proof of every engine interaction.
No current in-game failure was reported; no fresh runtime log is used as evidence.

[TESTED, offline Windows host Lua 5.4] Three regression assertions failed against
the old production code and passed after the root-cause fixes. All prior tests
continued to pass. The before-fix command was python scripts/test_lua.py (42 test
files after adding the debug regression, exactly three failures). Current suite:
44 test files, 49 Lua 5.1 syntax files, all passing.

| Priority | Reproduced defect | Root cause and correction | Regression |
| --- | --- | --- | --- |
| P2 | Without isDebugEnabled, the native blood spike installs a floor-render hook and exports a persistent sample command. | The guard tested only an existing false API. Require a positively true debug capability before registration. Manual sample placement also refuses MP clients. | test_debug_guard.lua; test_uv_reaction_prototype.lua |
| P2 | Mutating a retained fixture definition changes its callback/range and can opt into custom rendering after registration. | The adapter closes over the caller's mutable table. Capture the original callback and presentation opt-in once; continue reading live state through that callback. Unregister/register to change the definition. | test_fixtures.lua |
| P2 | Laser direction (1e308,1e308) reports distance 10 while the endpoint stays at the source. | Squared magnitude overflows to infinity, then normalization produces zeros. Reject non-finite magnitude before tracing. | test_lasers.lua |

These defects are demonstrated in host execution, not reported as PZ runtime
reproductions. The debug prototype remains a non-production FBO/depth experiment;
closing its guard does not prove native blood redraw or material fluorescence.

## Implemented L8 roadmap slice

Previously each cropLighting call traversed the nearby world separately. New
ConsumerExposure.sampleMany(points) captures sources once for 1-32 nearby points,
then evaluates each target's own 16-tile scope and strict geometry. The union scan
is capped at radius 32, 64 sources and 2048 inspected objects. Different floors,
unsafe/invalid points, over-budget arrays and oversized spans fail before scanning.
Missing metadata or truncated discovery cannot authorize complete exposure.
Queries return detached observations, perform no persistence, and retain no cache.

ConsumerIntegrations.cropLightingBatch(crops, options) inspects only the selected
page (default 16, maximum 32), reports stable input indices and rejected reasons,
and returns nextCursor plus sampled/rejected/complete totals. Cluster/span failure
is explicit; request smaller pages instead of silently clipping source coverage.
One valid cluster shares one scan. No full crop-array inspection, global world
traversal, scheduled tick scan, growth mutation or new gameplay authority exists.

Single-point observations keep their current shape. Authoritative Water treatment
still calls fresh single-point sampling and accepts no caller-supplied sample,
cache or client optical evidence. Medical, migration and Power ownership remain
unchanged. Array/page/scan bounds are implementation safety limits; no new sandbox
option is warranted for these read-only APIs. Existing gameplay settings remain
server interpreted. No new player-facing UI strings or translation keys are added.

Offline acceptance: multi/single-point parity, one scan for a 32-point batch,
separate wall results, fresh on/off state, mutable-result isolation, page bounds,
unchanged crop state, partial-source refusal and invalid input rejection. The
actual farmWorks crop provider also passes two-crop batch observation. Debug
mode provides LWIntegrationCropLightingBatch(crops, options) for manual inspection.

## Refreshed external pairing and remaining roadmap

[VERIFIED, source] Nightfall's current 0.29.0 checkout now requires
B47ANCEDHealthCare (current 0.10.0). The 0.27.0 medWorks Mod ID mismatch is closed
in the external source, without a Spectrum metadata/global alias. All three
source profiles pass. Their previous BLOCKED snapshots remain historical.
Exact versions, source hashes, HEAD and dirty states are retained in
validation/0.28.0-*.json. One earlier probe was correctly invalidated when a
read-only dependency changed during execution; a stable later probe passed.
Some dependencies remain dirty, so pin and verify matching installed source
before any game test. A source profile PASS does not run full mod bootstraps.

Still gated: native world-model rotation and blood/FBO rendering need verified
Lua routes and observed render ordering; no Java substitute. Fixture content,
Medical/Water timed gameplay actions and Farming growth remain consumer-owned;
this iteration changes no consumer files. Sunburn timing remains provisional.
Dedicated authority/sync, native inventory/fluids, rendering, controllers,
split-screen, save/streaming, reconnect and restart require actual PZ evidence.

[UNKNOWN] Full engine version; installed Steam build is 25485521. [RUNTIME GATE]
SP NOT TESTED; dedicated G7 BLOCKED / NOT TESTED; stable-release G8 BLOCKED.
No packaging, deploy, game/server launch, publication, merge or stable tag.
