# B47ANCED Spectrum Architecture

## Ownership

- `lightWorks_API.lua`: canonical bulb, light, compatibility-provider, visibility, and emission API.
- `lightWorks_ItemAccess.lua`: nil-safe access to inventory, containers, attachments, and weapon parts.
- `lightWorks_Vanilla.lua`: verified vanilla definitions and distributions.
- `lightWorks_UV.lua`: generic natural/artificial UV source attribution, sunlight queries, carried-emitter geometry, and exposure aggregation.
- `lightWorks_Sunburn.lua`: persistent authority-owned natural-UV dose,
  severity/recovery, bounded protection providers, and replay-safe treatment API.
- `lightWorks_LowPowerFlicker.lua`: deterministic visual gating from powerWorks'
  canonical read-only charge state; it never mutates activation or energy.
- `lightWorks_Patterns.lua`: bounded protected pattern definitions, persistent
  replay-safe selection, deterministic evaluation, and average duty-cycle export.
- `lightWorks_PatternMenu.lua` and `lightWorks_PatternServer.lua`: item-owned
  selection UI and server-owned resolution/mutation of carried light identities.
- `lightWorks_LightCatalog.lua`: bounded discovery, classification evidence, review queue, and export.
- `lightWorks_ContextMenu.lua` and `lightWorks_ChangeBulbAction.lua`: UI and transactional timed servicing.
- `lightWorks_ColoredTorches.lua`: client colored-light renderer, per-device range/strength/width/node/falloff profiles, and attachment-aware halo/cone geometry.
- `lightWorks_WorldEmitterManager.lua` and `lightWorks_VanillaEmitterAdapter.lua`:
  idempotent dropped/placed-item binding, semantic persistence, bounded lifecycle
  reconciliation, effect scheduling, and the sole `IsoLightSource` adapter.
- `lightWorks_EmissionSources.lua`: shared fixture and world-inventory source
  discovery used by downstream UV consumers; visible output, physical UV output,
  and RGB remain separate fields.
- `lightWorks_powerWorks.lua`: required family adapter that exports canonical light power profiles to powerWorks; it owns no batteries or charge state.
- `lightWorks_BurnoutAuthority.lua`: shared, server/SP-only wear progression,
  broken-bulb output and native inventory/mounted-part synchronization. The old
  client `lightWorks_Burnout` require path is a compatibility shim.
- `lightWorks_WorldDrop.lua`: shared authority hook that initializes world-active
  state and its billing checkpoint before vanilla drop transmission.
- `lightWorks_Operations.lua`: opaque UUID-based intent IDs. These IDs never grant
  permission; existing server identity/distance/ownership validation still applies.
- `lightWorks_AttachmentProfiles.lua` and `lightWorks_Hotbar.lua`: belt/webbing integration.
- `lightWorks_SpawnBulbs.lua`: spawn-time bulb selection.

## Rules

The registry is the only compatibility authority. Discovery never enables servicing. Verified core definitions or exact compatibility patches register serviceable lights. Bulb providers are independent, so a verified mod light accepts Nightfall UV bulbs automatically unless its provider restricts them.

powerWorks is required. Every registered light's declarative `power` profile is registered as a powerWorks consumer, including verified third-party lights and lights carrying Nightfall UV bulbs.

Callbacks fail closed on nil or unusual modded items. Servicing must preserve both bulbs if an inventory mutation fails. Background work stays bounded to local player inventories and cached catalog data; it never scans the world each frame.

lightWorks owns light state, emission semantics, UV source geometry,
natural/artificial attribution, sunlight exposure, and sunburn state. Sunburn
uses natural UVB only; artificial UV remains independently consumable and does
not cause ordinary sunburn. Protection providers return bounded fractions and
medWorks may call the replay-safe treatment API, but treatment content remains
medWorks-owned. It does not own Nightfall zombie damage, transformation, or
behavior. Canonical internal names are `lightWorks`; obsolete names are not part
of the current API.

Version 0.17.0 introduces the first persistent sunburn vertical slice. Canonical
updates are server/SP-only, elapsed time is clamped to prevent load spikes, and
only the bounded online/local player set is visited periodically. The default
45-minute onset, four-hour maximum, and recovery rate are provisional gameplay
values and remain explicit live-test gates.

Version 0.18.0 adds low-battery flicker to the shared colored-light renderer.
The canonical emitter object is used for handheld, attached, and weapon-mounted
lights. A stable item-derived phase prevents per-frame randomness; charge only
controls the off-window fraction. Unknown power state preserves normal rendering,
known zero charge emits nothing, and powerWorks remains the sole charge owner.

Version 0.19.0 provides steady, strobe, pulse, beacon, SOS, exact two-phase
alternating, and emergency double-flash patterns. Provider failures fail dark
without breaking the renderer. Pattern changes are authority/replay guarded and
roll back if powerWorks cannot refresh average demand.

Version 0.20.0 exposes those definitions through the registered light's existing
item submenu. Remote clients submit only bounded pattern, operation, and native
item IDs. The server resolves identity from the requesting player's inventory,
attachments, or carried weapon parts; it never trusts a client object reference
or searches nearby/world items. Successful changes use the existing item/weapon
state synchronization adapter.

Attachment types are capability-specific. Belt-down lights cannot enter webbing slots, angle-headed lights may use belt or webbing slots, and Heavy-Duty lights expose no wearable capability.

Emitter geometry belongs to the light definition; bulb output multiplies it.
This keeps a Heavy-Duty flashlight longer and stronger than a normal flashlight,
a penlight compact and narrow, a weapon light focused, and an electric lantern
radial. Vehicle headlights and placed world fixtures retain their native B42
renderers until separate obstruction-safe adapters are runtime-verified.

Version 0.21 adds first-class dropped/placed registered-light emission. The
inventory item remains authoritative for activation, bulb and power; transient
`IsoLightSource` references are never persisted. A durable ID, profile, mode,
orientation and active state live in item ModData and are rebound from nearby
world objects after load/revisit. Fixtures and `IsoWorldInventoryObject`
instances are collected from their distinct Build 42 square collections.
Pattern and low-charge phase derive from persistent world time and item identity
so visible and gameplay UV state do not independently drift between consumers.

Version 0.23 adds a world-object interaction boundary. Clients only request an
item ID, integer square, desired boolean state and bounded operation ID after a
timed adjacent interaction. The server resolves exactly one world backing at
that square, rechecks player distance, bulb and power, performs the replay-safe
mutation, and broadcasts semantic state. Clients then update only that exact
backing's transient renderer binding.

Version 0.24 prepares active powered world-inventory backings through Build 42's
inherited moved-object thump contract on both server and client. The shared
emission contract exposes a destruction provider only when the physical backing
supports `getThumpableFor` and `Thump`; Nightfall remains the behavior owner and
vanilla owns damage and networked removal.

## Spectrum branding compatibility

B47ANCED Spectrum is the display name. `lightWorks` remains the technical contract for Mod ID, source layout, Lua globals/requires, persistence, sandbox keys and networking. The rename adds no shared state, gameplay settings, migrations or new network paths. Existing server-authority and sandbox behavior is preserved; dedicated verification remains required. See [NAMING.md](NAMING.md).


## Audit fix ownership and persistence

See [AUDIT_FIXES.md](AUDIT_FIXES.md) for the nine fixes and their regressions.
Existing schema-1 world, pattern and sunburn tables retain their names and saved
content. World placement preserves durable identity/replay history and starts a
new world-only billing interval; a future schema is rejected without being reset.
Failed native placement restores the previous world-state reference and native
errors remain visible. Successful placement uses vanilla's existing full-item
transmission; the server hook does not load a client renderer.

World-energy checkpoints commit only after successful consumption. Switching an
active light first settles its preceding interval; a failed debit rejects the
transition and leaves its operation retryable. Depletion publishes the existing
world-emitter state message plus native field synchronization. Integration still
requires the power provider's failure/charge contract and actual dedicated tests.

Pattern disable forces a full steady duty cycle and rejects changes without
rewriting the saved selection. Unknown sunlight samples preserve dose/severity,
advance only the observation checkpoint and apply no retroactive exposure/healing.
UUID IDs preserve the existing bounded replay history and payload format; old
counter IDs remain historical entries. All clients must update to stop generating
old colliding IDs. No schema migration, new setting or custom Java is introduced.
