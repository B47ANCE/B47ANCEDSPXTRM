# EXT-35 — Bulbworks Compatibility and Migration Audit

Date: 2026-09-05  
Status: audit complete; migration blocked pending identity and authority decisions

## Clean-room provenance

This audit used inactive Bulbworks `42.20.3-0.4.0-0` at
`C:\Users\willi\Zomboid\Mods_Inactive\Bulbworks` only to observe identifiers,
persisted fields, public behavior, and event ownership. No code, assets,
definitions, text, recipes, balance values, or implementation structure were
copied. The inspected legacy API file had SHA-256
`C2798170ED4981E94DB2D13234EF01EC9FCD2E8D7CA89EB78BDF6C21F6DE2E5F`.

Current lightWorks source and tests are the implementation authority.

## Actual save/config evidence

Legacy compatibility is not hypothetical. Sixteen local saves explicitly list
`Bulbworks` in `mods.txt`. Bounded binary string inspection found the legacy
namespace in 24 save files, including player databases and streamed map chunks.
Representative records contain explicit installed bulbs, empty compartments,
burn minutes, burnout state, captured native light properties, and spawn context.

Both generations of Project Nightfall bulb IDs occur in saves:

- legacy `ProjectNightfall.UVBulb` and
  `ProjectNightfall.HighOutputUVBulb` occur in 61 and 58 files;
- current `ProjectNightfall.LightBulbUV` and
  `ProjectNightfall.LightBulbUVHighOutput` occur in 24 and 22 files.

Those counts establish evidence presence only. They do not establish that every
matching file contains a live recoverable item.

## Pipeline trace

Legacy Bulbworks owns a global `Bulbworks` registry, item ModData under
`Bulbworks`, context/timed servicing, spawn-time configuration, and a client tick
that ages player-owned active bulbs. Its public surface has 40 functions, all of
which have name-equivalent lightWorks calls.

Current lightWorks owns the `lightWorks` registry and item ModData namespace,
protected compatibility registration, transactional service snapshots,
powerWorks refresh, portable/world emission, patterns, UV, and burnout. Player
bulb aging still enters through a client `OnTick`; world items additionally have
separate server-owned activation/power and transient emitter lifecycles.

Enabling both mods would install two inventory menus, two spawn handlers, and two
burnout ticks against different ModData namespaces. Runtime coexistence is
therefore unsupported and migration must refuse to run while Bulbworks is active.

## Field compatibility matrix

| Legacy ID/key/API | Observed meaning/range | Exact lightWorks equivalent | Conversion and validation | Owner | Unknown/loss | Disposition |
| --- | --- | --- | --- | --- | --- | --- |
| Mod ID/global `Bulbworks` | Load identity and 40-call public namespace | Mod/global `lightWorks` | Do not create a runtime alias; consumers must update | Loader/consumer | Unknown external consumers | Unsupported alias; document only |
| Item ModData `Bulbworks` | Per-light legacy record | `lightWorks` | Never overwrite a non-empty current record | Item owner | Conflicting dual records need precedence policy | Quarantine conflict |
| `hasExplicitBulbState` | Boolean; distinguishes default from explicit empty/installed | Same key and meaning | Require strict boolean | Light state | Missing is implicit default, not `false` | Migrate if record otherwise valid |
| `installedBulb` | Full item type or absent for empty compartment | Same key and meaning | Require registered/current item identity or an approved alias | Light state | Obsolete/custom IDs may not resolve | Quarantine unknown ID |
| `burnMinutes` | Non-negative elapsed active minutes | Same key/unit | Require finite non-negative number | lightWorks burnout | Legacy invalid values were coerced; guessing would hide corruption | Migrate valid only |
| `burnedOut` | Strict boolean burnout marker | Same key and meaning | Require boolean and cross-check compartment/last type | lightWorks burnout | Contradictory combinations exist in representable schema | Quarantine contradiction |
| `lastBurnedBulbType` | Removed bulb identity after burnout | Same key and meaning | Require absent or approved bulb identity | lightWorks burnout | Obsolete/custom ID may not resolve | Quarantine unknown ID |
| `baseVisibleCaptured` | Native optical baseline captured | Same key | Require boolean | Light state | Does not prove values are still native | Migrate only with valid fields |
| `baseLightStrength` | Captured native numeric strength | Same key | Require finite non-negative number | Light state | None when valid | Migrate |
| `baseLightDistance` | Captured native numeric distance | Same key | Require finite non-negative number | Light state | None when valid | Migrate |
| `baseTorchCone` | Captured native cone flag | Same key | Require boolean | Light state | None when valid | Migrate |
| `baseTorchDot` | Captured native dot value | Same key | Require finite number in current accepted range | Light state | Exact accepted engine range needs runtime confirmation | Retain/quarantine pending range proof |
| `baseColorRed/Green/Blue` | Legacy item tint restoration values | Current cleanup consumes then deletes these keys | Require three finite values as one set | lightWorks visual cleanup | Partial triples are ambiguous | Migrate complete set; quarantine partial set |
| `spawnBulbContext` | Informational spawn category string | Same key | Bounded known string only | Spawn configuration | Third-party context vocabulary is unbounded | Preserve legacy evidence; do not drive behavior |
| Bulb profile data | Registry-time definitions, not persisted item truth | lightWorks bulb registry | Use current first-party definitions only | Registry | Legacy values/balance are not migration data | Never import |
| Light profile/tools/times | Registry-time definitions | lightWorks verified/core registry | Use current first-party definitions only | Registry | Legacy balance may differ | Never import |
| Visibility/emission APIs | Consumer queries derived from current bulb profile | Same-named lightWorks calls | Consumers move to current API | Consumer | Runtime aliases would perpetuate dual authority | No compatibility shim |
| Legacy event handlers | Inventory menu, spawn configuration, burnout tick | Current handlers | Bulbworks must be disabled | Each runtime | Duplicate effects if both load | Block coexistence |

## Item identity matrix

| Legacy identity | Current equivalent | Evidence | Disposition |
| --- | --- | --- | --- |
| Vanilla `Base.LightBulb*` identities | Same identities | Current Build 42/lightWorks registry | Exact |
| Legacy registered vanilla flashlight identities | Same identities | Current lightWorks registry | Exact |
| `ProjectNightfall.UVBulb` | Likely `ProjectNightfall.LightBulbUV` | Repository staging history and matching product role, but no current script alias or explicit migration contract | Blocked; Nightfall must declare alias |
| `ProjectNightfall.HighOutputUVBulb` | Likely `ProjectNightfall.LightBulbUVHighOutput` | Repository staging history and matching product role, but no current script alias or explicit migration contract | Blocked; Nightfall must declare alias |
| Any third-party bulb/light identity | No inferred equivalent | No bounded registry of legacy providers | Quarantine and retain legacy record |

## Phase B decision

Migration is required by real save evidence but is not yet safe to implement.

The exact known scalar fields can be converted without importing legacy balance.
However, the required all-items lifecycle is absent: no single authority-owned,
bounded hook currently discovers carried, nested, attached, weapon-part, dropped,
and streamed world lights, writes one idempotent migration receipt, synchronizes
that change, and guarantees that only lightWorks ages the bulb afterward.
Additionally, two obsolete Nightfall item IDs have no explicit current alias.
Choosing those replacements from apparent naming would be a behaviorally
significant guess.

## Required unblock work

1. Project Nightfall must explicitly own a versioned old-to-current bulb identity
   alias or mark the old items unsupported.
2. lightWorks must specify a server/SP authority entry point for one exact item,
   with stable item identity, bounded schema-1 receipt, idempotence, replay
   handling, and item-state synchronization.
3. Existing bounded inventory and world-emitter lifecycle paths must call that
   entry point only for items they already encounter; no global save/world scan.
4. Conflicting `Bulbworks` and `lightWorks` records must remain quarantined until
   an explicit precedence rule is approved.
5. Tests must cover no-state no-op, valid conversion once, replay no-op,
   malformed/unknown retention, old-ID aliases, dual-runtime rejection, burnout
   single ownership, save/reload, hosted replay, late join, and world streaming.

Until these conditions are met, legacy ModData remains untouched. No migration
version, partial current record, emitter, broken bulb, or lifetime update is
created from it.
