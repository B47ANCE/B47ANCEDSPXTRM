# Nine-defect audit fixes

Project Version: 0.25.5

The audit of `886f97d449de192a778dc241157948b5f9cf2214` reproduced nine defects
offline. All nine also reproduced before implementation on the `0.25.4` source
at `aecc9dbcd895aad0790968b2026152deea74da74`. This is a compatible PATCH: no
technical ID, save-key/schema, sandbox identifier, public consumer contract,
Workshop identity or artwork is renamed. No new gameplay option is introduced.

| Defect | Resulting behavior | Regression |
| --- | --- | --- |
| Client-only burnout | Shared server/SP authority advances wear, awards broken bulbs once and uses existing native inventory/weapon synchronization; client writers are rejected. | `test_burnout_authority.lua` |
| Client-only drop initialization | Shared native-completion hook initializes active/orientation/checkpoint state before vanilla transmits the placed item. No client renderer loads headlessly. | `test_world_drop_authority.lua` |
| Switch-off discards unpaid energy | The previous active interval settles before activation changes; a rejected operation remains retryable. | `test_world_power_settlement.lua` |
| Failed consumption advances checkpoint | A failed debit retains the old checkpoint; a retry charges the complete unpaid interval exactly once. | `test_world_power_settlement.lua` |
| Bulbless world light retains sources | Missing/unsupported bulb profiles unregister existing sources, identity indexes and physical targeting. | `test_world_emitter_manager.lua` |
| Counter IDs collide across clients/reloads | Menus obtain opaque native UUID-based IDs. Existing bounded replay history and server ownership/distance validation remain in force. | `test_operation_ids.lua`, `test_pattern_menu.lua`, `test_world_emitter_menu.lua` |
| Disabled patterns reduce battery demand | Disabled patterns use steady duty cycle 1 and reject server-side mutation; saved selections survive re-enable. | `test_patterns.lua`, `test_pattern_server.lua` |
| Incomplete sunlight heals sunburn | Unknown samples preserve dose/severity and advance only the observation checkpoint. Unknown time is not replayed later as known shelter/exposure. | `test_sunburn.lua` |
| Renderer disable strands sources | Disable removes owned sources and restores the exact suppressed native items, including weapon render objects; re-enable starts normally. | `test_colored_torches.lua` |

## Authority, persistence and failures

Burnout runs on server/SP only. Dedicated player enumeration does not require
local player slots; SP also works with an empty online collection. Player and
item duplicates are visited once per interval. The existing bulb lifetime,
enablement and servicing sandbox configuration is retained. The player cap and
elapsed-time clamp remain implementation safety bounds, not balance options.
Existing saved server/SP wear is retained; unsynchronized old client-only wear
cannot be safely recovered or trusted as server evidence. Dropped-light bulb
wear is outside the existing player-inventory burnout scope.

The native shared drop action remains the inventory/world mutation owner. The
hook initializes only registered world-capable lights on authority. Successful
placement uses vanilla's existing item serialization. Re-drop preserves schema-1
durable identity and replay history while starting a new world-only interval.
Rejected/unplaced completion restores the previous state reference; native
exceptions remain visible. Unknown schemas or malformed replay-history fields
are preserved and rejected, never replaced with empty user state.

World-energy checkpoints commit after a successful power-provider debit. A
failed debit rejects a pending switch and preserves the unpaid interval. Native
field synchronization observes the final activation state; depletion also reuses
the existing `worldEmitterState` message so clients clear saved active flags.
The provider must maintain its documented charge/failure contract. No power
ownership, battery representation or dependency API is reimplemented here.

Opaque UUIDs are intent identity, not permission. Existing payload string bounds,
owned-item resolution, world coordinates/distance checks and bounded replay
histories remain. Old counter IDs remain valid historical entries. Missing or
malformed UUID support fails closed rather than falling back to a restarting
counter. All clients need updated code to stop generating the old colliding IDs.
Pattern demand-refresh failure now preserves the existing replay history too.

## Source and offline evidence

- [TESTED, offline Windows] The original audit harness reproduced all nine
  defects before implementation. Eight regression files then failed against
  their corresponding old behavior; the settlement file covers two defects.
- [TESTED, offline Windows] The fixed suite passes 29 host Lua 5.4 regression
  files and 35 Lua 5.1 source/template syntax checks. Neither is PZ Kahlua.
- [VERIFIED, installed source] Steam build `25485521`; full game version UNKNOWN.
  The shared vanilla drop completion owns placement, full-item transmission and
  inventory removal. Its installed Lua SHA-256 is
  `1a1db7308a9cee66889ed197320d8ceb9a8373fcdf557d8e14d27b10ef644db3`.
- [TESTED, offline Windows] That installed vanilla Lua completion was executed
  with engine stubs and the actual shared hook. The transmission callback saw
  initialized state; no client renderer loaded. This is not native transport or
  dedicated-server runtime evidence. Raw game source is not bundled.
- [VERIFIED, installed source] Vanilla shared Foraging uses `getRandomUUID()`;
  server sources use `getOnlinePlayers()`. The new code uses exposed vanilla
  functions, never custom Java or a Java bridge. Runtime invocation remains a gate.

## Dedicated test plan and blockers

Use disposable saves and matching client/server source. Do not convert these
steps into PASS without observed runtime evidence:

1. Shorten bulb lifetime through the existing sandbox multiplier, keep a carried
   light active, and verify one server-owned burnout/output on two clients. Check
   nested inventory, a mounted weapon light, reconnect and restart persistence.
2. Drop an active light for the first time. Verify initial active/orientation
   state on both clients, ten-minute energy consumption, pickup/re-drop and
   save/reload behavior without duplicate sources or charged carried time.
3. Switch off between reconciliation points and verify elapsed energy is charged.
   With a disposable development provider that reports a known failed debit,
   verify checkpoint preservation, retry and no duplicated debit/output.
4. Exhaust a placed light and confirm both clients clear visible/UV emission and
   physical attackability. Remove/burn out its bulb and confirm no ghost source.
5. Alternate operations from two clients; reconnect/restart and repeat. New
   intents must succeed; replaying an identical request must be rejected.
6. Start with patterns disabled: full steady demand and no accepted pattern change.
   Re-enable and verify the saved selection is retained. Verify power drain too.
7. Supply an explicitly incomplete sunlight reading through a disposable fixture;
   dose/severity must hold. Only subsequent known shelter can recover dose.
8. Disable/re-enable colored rendering with handheld, attached and weapon lights.
   Verify custom sources disappear and native properties recover without ghosts.

G7 is **BLOCKED / NOT TESTED**; stable-release G8 is **BLOCKED**. No game/server
was launched, no real save was mutated, and no package/deploy/upload occurred.

Spectrum still requires technical Mod ID/namespace `powerWorks`. The current
local power-project source declares `B47ANCEDPower` and supplies
`B47ANCEDPower/Definitions`, not `powerWorks/Definitions`. This patch deliberately
preserves Spectrum's existing dependency contract; current-runtime pairing with
that migrated project needs a separately validated integration/adapter decision.
Offline power fixtures do not establish real dependency compatibility.

The audit's two additional observations (real-time flicker clock semantics and
remote-player custom rendering) were not among the nine requested defects and
remain unverified/unfixed by this slice.
