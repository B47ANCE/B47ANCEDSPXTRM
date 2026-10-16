# B47ANCED Spectrum Roadmap

> Consolidated status: [MASTER_ROADMAP.md](MASTER_ROADMAP.md).

lightWorks owns lighting, optical effects, UV, sunlight exposure, and sunburn. Bulbs remain a core subsystem. B47ANCEDPower owns electricity; consumer mods own domain-specific consequences. Historical milestones below retain their original dependency names.

1. **L0 — Rename and architecture:** clean namespace, modules, metadata, dependencies, documentation, and tests.
2. **L1 — Light-source core:** generic emitters, intensity, range, direction, falloff, source adapters, and bounded registries.
3. **L2 — Modular bulbs:** replacement, compatibility, lifetime, output, and spectrum.
4. **L3 — Portable and weapon lighting:** attachments, beams, work lights, and weapon modules.
5. **L4 — UV and sunlight:** natural/artificial attribution, efficient exposure aggregation, occlusion, and protection hooks.
6. **L5 — Sunburn:** dose, severity, recovery, persistence, authority, and treatment-consumer API.
7. **L6 — Lasers:** visible dots/beams, orientation, obstruction, range, and multiplayer presentation.
8. **L7 — Patterns:** strobe, pulse, beacon, SOS, alternating, and emergency lighting.
9. **L8 — Consumer APIs:** stabilize events and queries without per-entity global scans.
10. **L9 — Nightfall migration:** lightWorks exposure with Nightfall-owned infected damage and behavior.
11. **L10 — Optional integrations:** waterWorks UV treatment, farmWorks grow-light output, and medWorks sunburn treatment.

Current source includes L0-L5/L7 optical and bulb foundations, an L6 mounted-laser
presentation slice, explicit advanced fixture adapters, arbitrary-angle world-light
geometry, clothing protection/status and conservative known-record migration.
Current L8 adds bounded one-scan exposure batches and paged crop-light observations.
See MASTER_ROADMAP.md, CONSUMER_INTEGRATIONS.md and AUDIT_0_28_0.md for current
completion/gate status; FEATURE_COMPLETION.md retains the 0.26.0 milestone.
Native model rotation/blood redraw, live calibration, dedicated verification and
consumer-owned L9/L10 work remain gated; no Java fallback is authorized.

Version 0.25 adds deliberate cardinal aiming for directional dropped lights and
a bounded falloff-aware visible source chain that stops at verified wall
occlusion. The visible chain and semantic UV cone consume the same orientation.
The world-context action is timed, distance-checked, resolved by exact world
item ID on the server, persisted in item ModData, and replicated explicitly.
Free-angle placement and native presentation remain live-development work.

Version 0.21 adds bounded, idempotent dropped/placed world emitters. It scans
both fixture and world-inventory collections, preserves placement direction for
directional UV, uses one scheduler for timed emitters, and leaves steady lights
on low-frequency validation. Dedicated-server synchronization, chunk stress,
destruction, and long-duration drain remain explicit live validation gates.

Version 0.23 adds server-validated timed world-light activation and explicit
client convergence. Deliberate orientation placement UI and physical zombie
destruction remain separate roadmap work; ordinary world switching no longer
requires picking the item up.

Version 0.24 completes the first physical-destruction adapter for dropped world
lights through the verified vanilla thump path. Native zombie animation,
destruction duration, item removal, and dedicated-server replication remain
in-game gates rather than host-test claims.

Version 0.20.0 adds a player-facing pattern submenu to each registered light's
own item menu. Single-player changes use the canonical pattern API directly;
multiplayer requests resolve stable item IDs only inside the requesting player's
carried, attached, or weapon-part items before server mutation and sync. Native
menu presentation and hosted/dedicated replication remain live validation gates.

Version 0.19.0 implements the bounded pattern registry and built-in steady,
strobe, pulse, beacon, SOS, alternating, and emergency patterns with persistent
authority/replay-safe selection and average powerWorks duty-cycle demand.
The registry and power accounting remain the canonical pattern ownership layer.

Version 0.18.0 adds configurable deterministic low-charge flicker for handheld,
attached, and weapon-mounted emitters without mutating activation or drain.
Native visual timing and multiplayer presentation remain live validation gates.

Version 0.17.0 adds natural-UV-only sunburn dose, severity, sheltered recovery,
bounded protection providers, replay-safe treatment, persistence, and sandbox
controls. Timings are provisional; native presentation, clothing providers,
save/reload, multiplayer replication, and medWorks treatment remain validation
or consumer-development gates.

Version 0.16.0 activates physical cell-count profiles through powerWorks 0.7.0:
standard, heavy, angle, army-angle, crafted lantern, and crafted flashlight
compartments use two cells; penlights and provisionally classified gun lights use
one. Angle-headed variants now use the documented D-cell family. Taped packs
remain single removable units. Runtime and multiplayer validation remain gates.

Version 0.15.7 gates registered portable UV emitters through powerWorks'
canonical charge decision, fails closed on uncertain power or activation, uses
the native active-light list for weapon modules lacking activation accessors,
and unwraps Build 42 attached-item entries. Native mounted-light and drain-to-zero
behavior remain release validation gates.

Version 0.15.8 rejects non-finite modifiers, geometry, intensity, range and
spectrum values at the UV aggregation boundary. World and mounted collections
are integer-bounded, invalid coordinates fail closed, and malformed third-party
emitters cannot poison totals or suppress valid sources. Native occlusion and
multiplayer discovery remain planned validation/development work.

## Approved external-research addition

**EXT-35 — Bulbworks compatibility and migration audit:** inventory legacy IDs,
saved schemas, public API consumers, bulb profiles, replacement state, lifetime,
and burnout ownership. Specify a one-way idempotent migration into explicit
lightWorks semantics, preserve or quarantine unknown state, and record migration
version. Bulbworks and lightWorks must never run competing burnout authorities.
No third-party code, definitions, balance, or assets will be copied.

The Phase A/B audit is complete in `BULBWORKS_MIGRATION_AUDIT.md`. Actual saves
contain legacy item state, so compatibility is required, but implementation is
blocked: obsolete Nightfall bulb identities lack an explicit alias and no single
authority-owned bounded migration/synchronization path currently covers carried
and streamed-world items. Legacy data remains untouched until both gates close.


## Migration implementation follow-up

The dated Phase B conclusion above is historical. Current authority callers and
receipt/quarantine handling are implemented in LegacyMigration; known registered
records can convert. The two evidenced Nightfall stored-field IDs now have explicit Spectrum-owned
aliases (0.27.0). Conflicting records and other unknown identities remain
quarantined. See CONSUMER_INTEGRATIONS.md; FEATURE_COMPLETION.md is historical.
