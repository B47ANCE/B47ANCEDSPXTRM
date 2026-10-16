# Build 42 world-emitter audit

Verified against the installed Build 42 game archive on 2026-08-30. This note
records behavioral conclusions; it does not reproduce vanilla source.

- `IsoWorldInventoryObject` only schedules its contained item when
  `InventoryItem.shouldUpdateInWorld()` returns true.
- Ordinary drainable lights do not qualify merely because they are activated;
  the drainable implementation limits world updates to unrelated temperature
  and rain-sensitive behavior.
- Vanilla equipped-item drain also deactivates an activated item when no owning
  player is found. It therefore cannot provide authoritative dropped-light
  runtime or drain behavior.
- `InventoryItem.syncItemFields()` has a verified server path for a world item
  and distributes item statistics to nearby clients.
- `IsoWorldInventoryObject` inherits the vanilla moved-object thump contract.
  Its ordinary state is not targetable, but the verified moved-thumpable flag
  makes `getThumpableFor()` return the physical object; vanilla `Thump()` then
  owns damage, sound, target clearing, networked square removal and destruction.

Consequences:

1. lightWorks persists intentional world-active state separately from the
   transient native equipped flag.
2. powerWorks exposes absolute hourly consumer demand derived from the same
   device, load, UV, resistance and pattern multipliers used for equipped drain.
3. lightWorks consumes that energy at bounded ten-minute reconciliation points
   and catches up elapsed unloaded time arithmetically when the item is revisited.
4. Depletion disables both visible and semantic UV emission and synchronizes the
   changed item fields. Native world-item rendering and persistence remain owned
   by Project Zomboid.
5. Only active powered world emitters enable the inherited physical thump
   contract. lightWorks exposes that verified backing; Nightfall decides whether
   and when an infected should attack it.

Dedicated-server replication and long-duration balance remain mandatory in-game
release gates; this installed-class audit establishes the required code path but
does not substitute for those tests.
