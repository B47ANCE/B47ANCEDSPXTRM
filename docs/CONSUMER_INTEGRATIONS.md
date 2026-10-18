# Spectrum consumer contracts

Project Version: 0.30.1

Artwork-only patch; prior source/offline observations retain their originally
recorded versions. No consumer pairing or PZ runtime evidence was refreshed.

This MINOR iteration adds optional API capabilities and four sandbox settings.
Technical Mod ID, namespace, Workshop item and existing save schemas stay intact.
The current scope allows isolated Health Care self-care and Nightfall dependency changes. Water and Farming source remain unchanged.
No consumer source, assets or implementation bodies are copied into this project.

## Nightfall stored-bulb compatibility, contract 1

Spectrum owns `B47ANCE/Spectrum.Nightfall.v1`. This owner decision supersedes the
0.26.0 wait for a declaration inside Nightfall, for these two stored fields only:

| Legacy identity | Registered destination |
| --- | --- |
| ProjectNightfall.UVBulb | ProjectNightfall.LightBulbUV |
| ProjectNightfall.HighOutputUVBulb | ProjectNightfall.LightBulbUVHighOutput |

Both destinations must be registered with the PROJECT_NIGHTFALL tag. Registration
runs at adapter load, after later bulb registrations and on game/server startup.
Conflict and registry-capacity checks precede either alias. No conflicting owner
entry is overwritten. `API.ConsumerIntegrations.aliasContract()` returns a copy.

Existing authority-only LegacyMigration converts installedBulb and
lastBurnedBulbType in recognized Bulbworks records, preserving wear, burnout,
original fields and its durable receipt. Unknown fields, conflicting current and
legacy state, or an active/unknown Bulbworks runtime remain quarantined. This
neither creates old standalone script items nor rewrites arbitrary inventory IDs.
Use disposable fixtures; backward migration/downgrade is unsupported. Restore an
untouched save backup to roll back. Clients cannot perform conversion.

## Optional Medical procedure delegation

`API.ConsumerIntegrations.treatSunburn(patient, amount, operationId, treatmentSource)`
checks authority, bounded IDs and amount 0.01-0.5, then delegates the registered
`medWorks.treatSunburn` procedure. The maintained B47ANCEDHealthCare checkout still
exports the medWorks Lua API. Spectrum adds no obsolete Mod ID/global alias.
Medical owns reservations, locks, validation and uncertain-operation recovery;
Spectrum Sunburn retains canonical dose/severity and treatment replay state.
The trusted server caller owns its gameplay action, consent, reach, inventory
costs and a fresh durable operation ID. The bridge remains trusted-only. Health Care 0.11.0 adds separate native timed cold-pack self-care with consumed supplies; no free client RPC is added.

## Optional Water treatment

`API.ConsumerIntegrations.registerWater()` registers `lightWorks.uvc.v1` only when
the supported existing waterWorks API is loaded. Conflicting treatment IDs are
rejected. `treatWater(owner, operationId)` invokes Water's normal transaction.
The registered validate callback enforces the same gates even when a trusted
consumer calls Water's API directly. The server recomputes exposure at the placed
container; callers cannot supply location, spectrum or intensity.

The opt-in action is a single normalized gameplay pulse. It is not a physical
UV dose/time calculation, sterilization claim, or statement that water is safe to
drink. Only the biological quality axis is reduced; chemical, salinity,
particulate and turbidity values stay unchanged. A nonempty legacy water object
or positively confirmed unmixed native water container is required. No target
position, unknown optical path, budget-limited scan, insufficient UVC, excessive
turbidity, malformed history or retained duplicate operation ID can pass.
Water owns quality normalization, journal, rollback/recovery, bounded history and
native synchronization. Duplicate protection uses its retained 16-entry history;
it is not an unlimited exactly-once guarantee. Calls require trusted server action
validation and must not be made repeatedly per tick. Uncertain transactions remain
blocked by Water recovery. Native fluid replication is a runtime gate.

| Sandbox key (lightWorks) | Default | Bounds |
| --- | --- | --- |
| EnableWaterUVIntegration | false | boolean |
| WaterUVMinimumIntensity | 0.5 | 0.001-100 |
| WaterUVMaximumTurbidity | 0.25 | 0-1 |
| WaterUVBiologicalReduction | 0.90 | 0-0.99 |

These settings are server interpreted, validated by the existing Sandbox schema,
and labeled/tooltipped in every existing translation folder using English fallback
where untranslated. Native double controls are continuous within bounds; no
invented step contract is asserted. Existing saves default to the disabled opt-in.
The reduction and threshold remain provisional gameplay tuning, pending tests.

Current Nightfall bulbs omit a spectrum and therefore use the existing UVA
default. They cannot trigger this UVC action. SPXTRM now registers a purpose-built lightWorks.UVCServiceLamp and matching UVCBulb; the ordinary Nightfall UVA bulbs remain unchanged. Water's older powerWorks hardware paths remain owned
by Water and are not repaired through a global alias.

## Optional Farming observation

`API.ConsumerIntegrations.cropLighting(crop)` uses farmWorks.inspectCrop and returns
a detached bounded optical observation at its native coordinates. It omits source
references, callbacks, anatomy/inventory data and mutable crop objects. It reports
`growthEffect=NONE`. The existing Farming API has no supported growth/light
mutation boundary. This is not a grow-light system or an agronomic lux/PAR model.
No crop growth, health, water, persistence or server-owned crop state is changed.

`ConsumerExposure` scans registered dropped/world and fixture sources within
16 tiles on the same floor, with 64 source / 2048 unique object budgets. Invalid
or unsafe native-grid coordinates are rejected before scanning. These
are technical safety limits, not gameplay settings. UV uses the existing strict
occlusion API; visible light uses the same native boundary path. Windows transmit
visible light and block treatment UVC by deliberate conservative policy. Missing
sunlight evidence makes total illumination unknown; artificial-only Water checks
do not require sunlight. Scope is discovered loaded registered world/fixture
sources: carried lamps, global scene lighting and unloaded cells are not measured.
Completeness means that scoped calculation finished, not a complete engine light
field. Sampling is on demand, never an automatic per-tick world traversal.

## Batched read-only queries

`ConsumerExposure.sampleMany(points)` accepts a dense array of 1-32 finite world
points and returns an observation array plus query metadata: scans, points,
scanRadius and capturedSources. Each observation retains the single-point shape
and 16-tile registered world/fixture scope. Points must share one floor and fit a
cluster whose union source scan is at most radius 32. Source/object budgets are
shared across the capture; a partial scan makes all affected observations
incomplete. Split a wide or crowded field into smaller calls; failure never means
known darkness. Single-point sample now uses the same bounded evaluator. Provider callbacks
report owner facts; in a batch, context.center is the shared capture anchor, not
each observation target. Queries expose no provider callback or source object.

`ConsumerIntegrations.cropLightingBatch(crops, {cursor=0, limit=16})` reads only a
page from a caller-supplied crop array. Limit is 1-32; cursor is a nonnegative
integer within the array. Results contain original input index, ok, and either
observation or reason. The page reports sampled, rejected, complete, nextCursor,
and successful query metadata. Empty pages perform no scan. A valid inspection
with unknown optical facts may have ok=true but observation.complete=false;
callers must check completeness, not merely ok. Crop objects/source references
never escape in output. No crop growth or persistence is changed.

Batch results are immediate observations, not reusable treatment evidence or a
long-lived lighting cache. Water always recomputes its own single-point optical
facts on the authority. These query sizes are technical resource budgets, not new
gameplay settings. Debug helper: LWIntegrationCropLightingBatch(crops, options).

## Source pairing and test status

[TESTED, offline Windows host Lua 5.4] Actual API slices passed for Nightfall bulb
registration/migration, Medical treatment/replay, Water gate/write/rollback and
Farming single/batched observations. Native objects are stubs; full bootstraps
were not loaded. The exact inventory is in validation/0.28.0-consumers.json.

[VERIFIED, source] The current Nightfall 0.29.0 checkout declares
B47ANCEDHealthCare, matching the current medical Mod ID (0.10.0). The 0.27.0
loader mismatch is resolved in the external checkout. Core, Nightfall and
consumer source preflights pass. All external projects remain read-only to this
task; dirty dependency snapshots are recorded and must be reviewed/pinned before
installation. Historical validation/0.27.0-* records retain their original blocker.

Source and API PASS do not verify installation, exact engine version, SP or
dedicated behavior. See IN_GAME_TEST_HANDOFF.md and AUDIT_0_28_0.md.
SP NOT TESTED; G7 BLOCKED / NOT TESTED; stable-release G8 BLOCKED.

## Post-commit observation

Optional consumers can invalidate their own caches through the version-1
Notifications observer surface. See CONSUMER_NOTIFICATIONS.md for producer scope,
late attachment, safe teardown and failure/drop diagnostics. No bus event grants
a treatment, inventory action, crop mutation or client authority. Domain-owned
transactions remain with Medical/Water/Farming and are not globally mirrored.

## 0.30.0 player action

The selected placed-container UVC action is implemented by SPXTRM through a shared native timed action (WaterUVTreatmentSeconds 30, bounds 5-600). Its read-only preview is never transaction evidence. Completion validates actor reach/liveness, exact placed backing and recomputes current quality/exposure using Water's existing owner transaction. No Water source edits or inline device integration. GrowLamp supplies visible optical observations only. See FEATURE_PASS_0_30_0.md.
