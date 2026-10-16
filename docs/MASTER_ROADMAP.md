# B47ANCED Spectrum Master Roadmap

Canonical version: 0.27.0.

## Implemented in source with offline coverage

- L0-L3: identity/tooling, generic light/bulb registries, servicing, lifetime,
  server-owned burnout, portable/attached/weapon rendering, cell profiles and
  maintained B47ANCEDPower integration. Existing lightWorks save/API identity stays.
- L4-L5: attributed natural/artificial UV, strict complete-sample/occlusion APIs,
  persistent server-owned sunburn, clothing coverage/holes, protection/treatment
  contracts, sandbox controls and read-only player status.
- L6: registered mounted aiming lasers, bounded obstruction/range queries and
  cached local/nearby-remote UI dot/optional beam presentation. No combat changes.
- L7-L8: protected pattern registry, server-owned replay-safe selection, demand,
  exact fixture-provider contracts, bounded discovery and retained consumer APIs.
- World lights: durable state, native backing, activation, elapsed drain,
  arbitrary-angle/cardinal aiming, shared visible/UV geometry, explicit replication,
  physical-thump adapter, cleanup and conservative known-record migration.
- Audit improvements: real-ms flicker; nearby remote-light rendering; every-boundary
  beam checks; bounded inventory recursion; strict UUID/history/state handling.

All nine 886f97d defects remain covered. See the historical AUDIT_FIXES.md and
0.26.0 FEATURE_COMPLETION.md for exact behavior and compatibility limits.

## External or blocked implementation

- Native world-model rotation: no verified safe Lua contract. Arbitrary-angle light
  geometry is implemented; do not substitute custom Java.
- Native blood/material redraw: the existing opt-in prototype needs its FBO/depth
  spike before production. Arbitrary shaders are not exposed by a verified Lua API.
- The two evidenced Nightfall stored-bulb aliases are now declared by Spectrum.
  Conflicting dual records, other unknown identities and old standalone script
  items remain quarantined/unsupported.
- L9/L10: Spectrum-side aliases, Medical delegation, opt-in UVC Water transaction
  and Farming optical observations are implemented. Infected effects, complete
  Medical/Water action content and crop growth remain owned by consumers. Full
  Nightfall startup is blocked by the old medWorks Mod ID; all consumers remain
  read-only. See CONSUMER_INTEGRATIONS.md and IN_GAME_TEST_HANDOFF.md.
- Additional fixture/item content needs exact approved definitions/assets. The
  generic advanced fixture capability is implemented without invented content.

## Runtime gates and release status

Portable/mounted/world discovery, native colors/cones, laser UI projection/depth,
controllers/split-screen, native zombie animation/destruction/removal, drain,
clothing coverage, save/reload, streaming, late join, reconnect and restarts need
observed PZ evidence. Sunburn timing remains configurable and provisional.

Offline checks and the source-integration probe are not SP or dedicated evidence.
G7 BLOCKED / NOT TESTED; stable-release G8 BLOCKED. Packaging, deployment, game/server
launch and Workshop upload were not requested or performed. See TESTING.md and
VALIDATION.md for exact commands and acceptance scenarios.
