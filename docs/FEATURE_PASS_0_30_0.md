# Feature pass and acceptance

Project Version: 0.30.0

Scope supersedes the earlier blanket consumer-read-only decision only where explicitly allowed: Health Care treatment in an isolated checkout; Nightfall dependency metadata after authorized main reconciliation. Water/Farming remain unchanged at the user's later direction. No additional growth behavior is installed into Farming.

## Implemented source

- `lightWorks.UVAInspectionLamp` / UVABulb: UVA only, normalized intensity 1, range 10.
- `lightWorks.UVCServiceLamp` / UVCBulb: UVC only, normalized intensity 2, range 6.
- `lightWorks.GrowLamp` / GrowBulb: visible light, range 8; no crop mutation.
- All three devices use two nominal AA cells through Power, canonical burnout/pattern/world activation, tool-based bulb servicing and matching-bulb-only replacement. Native icon/model references reuse the installed vanilla housing, not copied assets. Item script and loot parsing remain native test gates. Ordinary incandescent torches reject specialist bulbs, and specialist housings reject ordinary bulbs.
- MedicalStorageTools receives rare inspection/service devices and spare bulbs; GardenStoreTools receives grow lamps/bulbs. OpticalDeviceLootMultiplier defaults 1, bounded 0-10; zero prevents future specialist loot. Registration is idempotent. Existing items persist when loot is disabled.
- `lightWorks_WaterTreatmentAction`: native shared timed action, default 30 seconds (sandbox 5-600). Same-floor three-tile reach, exact placed backing and known living actor; rechecks complete current UVC/quality/power on completion. Server allocates operation identity and uses Water's registered transform/rollback/history. No new client commit RPC. Action duplicate callbacks terminate; cancellation consumes no fluid. Only biological quality is reduced, with the existing disabled-by-default Water opt-in.
- ModelAlignment contract 1: exact item, evidenceId, northYaw [0,360), clockwiseSign +1/-1. Registration copies definitions; max 64. EnableNativeModelAlignment defaults false. No unmeasured built-in profile. Authority applies only to registered directional world lights after logical orientation commits and during backing reconciliation. Verified native readback and complete-item transmit required; failed writes restore original yaw, retaining durable recovery if restoration/sync is unproved. `restore(item)` never changes optical orientation. Native X/Y tilt remains unchanged.
- ReactiveMaterials contract 1: copied bounded registration (64), explicit UVA/UVB/UVC excitation, threshold, color and absorption/fluorescence/reflectance response. evaluate requires complete artificial optical facts and returns detached presentation hints with identityConfirmed=false. UntreatedBlood is absorption; FluorescentMarker is a registered marker concept. No renderer automatically installs an overlay or modifies native blood. Chemical effects need their own owner/timing contract.
- Health Care 0.11.0 supplies cold-pack self-care: main-inventory Base.Coldpack, native authority timer, no other-player consent ambiguity, existing Medical locks, consumed input before canonical Spectrum dose mutation and durable uncertain-operation inspection. Its original artwork checkout is untouched.

## Required acceptance / remaining implementation

Test the three devices through spawn, service, battery installation/depletion, patterns, dropped activation, occlusion, pickup/reload and two-client late join/restart. Exercise the timed Water action with lost power/blocked UVC/moved target/cancel/repeated callbacks and native fluid replication. Test Health Care self-care with interruptions, native action serialization, removal failure and restart recovery.

Per-model measured calibration is still required before default alignment can be enabled. Blood/FBO invocation, render order, depth/occlusion and arbitrary materials have no production-safe verified route; existing manual debug spike remains the next evidence step. Crop growth and Water-owned inline devices/recipes remain outside the currently permitted edits. Sunburn, optical intensity and treatment timing remain provisional, configurable gameplay approximations. All actual SP/dedicated cases are NOT TESTED; G7/stable G8 BLOCKED.
