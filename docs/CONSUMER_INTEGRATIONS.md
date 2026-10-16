# Spectrum consumer contracts

Project Version: 0.27.0

This MINOR iteration adds optional API capabilities and four sandbox settings.
Technical Mod ID, namespace, Workshop item and existing save schemas stay intact.
The user selected Spectrum-only integration; all consumer folders remain read-only.
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
costs and a fresh durable operation ID. No new client RPC or free treatment UI
exists. This bridge is an API slice, not completion of Medical's treatment content.

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
default. They cannot trigger this UVC action. No UVC production item is invented;
a test provider/device must explicitly establish known power, activation,
geometry and UVC spectrum. Water's older powerWorks hardware paths remain owned
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

## Source pairing and test status

[TESTED, offline Windows host Lua 5.4] Actual API slices passed for Nightfall bulb
registration/migration, Medical treatment/replay, Water gate/write/rollback and
Farming observation. Native objects are stubs; full bootstraps were not loaded.
The source inventory and exact hashes are in validation/0.27.0-consumers.json.

[VERIFIED, source] During this task the medical checkout was externally renamed
from medWorks to B47ANCEDHealthCare 0.9.3. Nightfall 0.28.0 still requires Mod ID
medWorks. The current Nightfall preflight is BLOCKED by that missing ID. Earlier
experienceWorks dependencies observed in the old medWorks tree are historical;
the renamed checkout uses B47ANCEDKnowledgeAndWisdom. Do not invent aliases to
conceal this mismatch. Medical and Knowledge dirty checkouts were observed, so
rerun fingerprints and source preflight immediately before any installation.

Core Spectrum + Power source preflight passes. This does not verify installation,
exact engine version, SP or dedicated behavior. See IN_GAME_TEST_HANDOFF.md.
SP NOT TESTED; G7 BLOCKED / NOT TESTED; stable-release G8 BLOCKED.
