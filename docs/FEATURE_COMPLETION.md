# Spectrum feature completion

Project Version: 0.26.0

Starting point: 0.25.5, commit eae1e6f. This MINOR iteration adds optical APIs,
free-angle aiming and sunburn presentation/protection. The loader now requires
`B47ANCEDPower`, matching the maintained power project. Existing servers must
update that dependency before updating Spectrum. Its `lightWorks` identity,
existing save keys, sandbox keys, Workshop item and artwork remain intact.

## Completion ledger

| Work | Source/offline result | Remaining gate |
| --- | --- | --- |
| Maintained power integration | Canonical Definitions/global selected first; feature-detected registration; all power readers and developer kits updated. Actual-source integration probe passes. | Matching installed client/server dependency; native transport/drain. |
| Remaining audit observations | Millisecond flicker clock; nearby remote-player rendering and disconnect cleanup. No per-frame inventory recursion. | Two-client visual timing, clock skew and reconnect. |
| Free-angle world aiming | Aim along the player's facing before walking; saved finite angles share validation, UV direction and visible chains. Cardinal saves remain valid. | Native presentation/model rotation. |
| Directional/occlusion improvements | Check every traversed boundary, including thin walls between visible nodes; unknown paths stop presentation. | Visual spill, glass/doors and streaming in PZ. |
| Lasers | Base.Laser on an aimed weapon yields bounded ray/dot presentation; optional beam line and exact-profile registration. | Projection, scene depth, zoom, controller and split-screen. |
| Advanced fixture adapters | Bounded registration of known power/activation, directional visible/UV facts and optional custom presentation. Native fixtures keep native rendering. | Real authoritative fixture providers and runtime tests. |
| Sunburn presentation/protection | Read-only local world-menu status; clothing coverage/holes/deduplicated layers; validated sandbox controls. Unknown protection pauses dose/recovery. | Native clothing evidence and provisional timing calibration. |
| Legacy migration | One exact-item authority boundary used by encountered carried/nested/attached/weapon and world/drop lights; receipt, native sync and quarantine. Originals retained. | Native save/reload/streaming and owner-declared Nightfall aliases. |
| Hardening | Bounded inventory discovery, strict UUID/history checks, future-state retention, monotonic sunburn time and client physical-damage rejection. | Dedicated persistence/reconnect/stress tests. |

These are implementation and offline results, not PZ runtime completion claims.

## Authority and persistence

Server/SP owns bulb wear, conversion, patterns, world activation/orientation,
energy settlement and natural-sunburn dose. Existing bounded network intents
resolve exact nearby/owned item identities on the server. World aiming now shares
activation's replay history. Invalid/future state and histories are rejected intact.
Clients render synchronized facts; they never own power, damage or treatment.

Native placement, destruction and removal remain native. Physical attacks reject
clients. Native object-removal events clean visual bindings, with reconciliation
for pickup, streaming, lost bulbs and lost power. No substitute zombie AI,
animation, damage, item removal or custom Java is introduced.

`lightWorksWorldEmitter.orientation` extends schema 1 with a finite numeric angle
in [0,360), clockwise from north, alongside existing cardinal strings. Update all
clients/servers together. Downgrade after using numeric angles is unsupported:
prior renderers cannot interpret them. Bulb/pattern/sunburn schema versions remain
unchanged. New `lightWorksLegacyMigration` receipts use schema 1 with item ID,
status and reason. Keep disposable pre-upgrade backups; reverse migration is not
provided.

Legacy conversion never imports definitions/balance or runs the old implementation.
An active or unverifiable Bulbworks runtime blocks conversion. Known valid scalar
fields and registered exact bulb identities convert once; empty compartments stay
empty and wear is preserved. Conversion never awards another broken bulb. Nonempty
dual records, malformed fields, unknown receipts and unresolved IDs stay untouched
and fail closed. The legacy table is retained. No Nightfall alias is inferred.

## Public APIs and consumer contracts

- `lightWorks.registerPowerProfiles()` refreshes late light registrations. It
  returns false for an unavailable/incomplete provider. `lightWorks.powerWorks`
  remains the adapter reference; no global or saved power namespace alias is made.
- `lightWorks.Lasers.register{item,range,color={r,g,b}}` registers exact mounted
  profiles. Base.Laser uses the native Canon slot. Lasers add no accuracy bonus,
  damage, energy store, ammo mutation or new gameplay protocol.
- `lightWorks.Fixtures.register{id,inspect,customPresentation=false}` registers a
  provider. The callback returns nil for other objects, or a table with `known`,
  `active`, `powered`, `range`, `intensity`, optional `directional`/`orientation`,
  `color` and `uv={intensity,range,spectrum={uva,uvb,uvc}}`. All numbers are bounded
  and finite. Unknown facts never become a confirmed emitter. Owners persist and
  synchronize their state. `customPresentation=true` opts into Spectrum sources;
  do not combine it with another renderer for the same fixture. Use
  `Fixtures.unregister(id)` to remove an adapter.
- `lightWorks.LegacyMigration.process(item,player?,parentWeapon?)` is the one
  authority conversion boundary. `registerAlias(oldType,newType,owner)` requires
  an explicit owner and registered replacement; it creates no script-item alias.
- `Sunburn.getState(character)` supplies presentation. Medical owns its content,
  timed actions and inventory transactions, then invokes authority-only,
  replay-safe `Sunburn.applyTreatment(character,amount,operationId)`. No client
  request accepts self-reported treatment.
- Nightfall owns infected effects and must check `UV.getVerifiedExposure`'s
  `uv.complete`. Water/Farming likewise own treatment/crop state, calibration and
  configurable effects; Spectrum supplies optical facts, not invented biology.

## Settings, localization and budgets

New settings use the existing `lightWorks` sandbox page. Missing values use defaults;
strict boolean types and finite/clamped numbers apply on server and clients. The
sunburn maximum/onset and flicker fraction ordering is reconciled consistently.

| Setting | Default | Bounds/behavior |
| --- | --- | --- |
| EnableClothingSunProtection | true | Server reads actual worn coverage. |
| SunburnClothingProtection | 0.90 | 0–1 attenuation of intact covered regions; gameplay approximation, not measured UPF. |
| EnableLasers | true | Native aiming/attachment presentation. |
| LaserRangeMultiplier | 1.0 | 0.1–2, within internal 32-tile trace cap. |
| EnableLaserBeams | false | Optional UI line; dot remains. |

Disabling world emitters suppresses custom/dropped semantic output, presentation,
physical targeting and energy billing while retaining desired activation. Billing
checkpoints advance during disabled reconciliation, so reconciled disabled intervals
are not charged on re-enable. An unloaded emitter spanning a sandbox policy change
needs runtime/accounting review; no historical config timeline is inferred. Native
fixtures and carried lights remain separate.

Existing sunburn timings remain provisional and configurable. The 29 language
folders retain previous translations and use explicit English fallback text for
new keys; human translations are pending. Registry/replay/geometry/UI budgets are
internal safety limits, not balance controls. Nearby portable rendering is limited
to 32 tiles on the same floor. Laser geometry is sampled every six ticks, caps 16
active rays and renders cached results. Custom fixtures scan every 120 ticks and
cap 64 records. Inventory discovery caps 1,024 items and 64 nested containers;
overflow is skipped safely. No global world/save scan is used.

## Explicit blockers and external work

- Native model rotation and arbitrary blood/material shaders lack a verified safe
  Lua contract. Free-angle light geometry and the existing opt-in blood prototype
  are the alternatives. The prototype remains non-production; native redraw needs
  the FBO/depth spike in `UV_REACTIVE_MATERIALS_FEASIBILITY.md`.
- Zombie destruction presentation, late join, streaming, drain, save/reload and
  restarts need actual PZ evidence. G7 BLOCKED / NOT TESTED; stable G8 BLOCKED.
- Nightfall migration/effects and Medical/Water/Farming actions need their owners'
  contracts. This iteration writes Spectrum only. Obsolete Nightfall IDs stay
  quarantined until explicit aliases exist.
- Live timing calibration and new fixture/item content need play evidence or
  concrete definitions. No unverified content or biological models are invented.

No package, deployment, upload, game/server launch, real-save conversion,
other-repository write or stable tag is included.
