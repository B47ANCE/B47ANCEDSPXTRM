# Bulb action lifecycle — 0.15.1

## Native item-state synchronization — 0.15.6

Service completion now requests syncItemModData, syncItemFields and
syncItemActivated for ordinary inventory lights. Mounted targets instead request
syncHandWeaponFields on the parent weapon. Native inspection confirms that weapon
packet serializes full attachment items; a containerless part cannot safely use
the container/item-ID ModData packet. Success and rollback/inspection states use
this path. Sync failure is reported without retrying the committed mutation.

Host tests verify packet selection and exception isolation, not network delivery.
Test remote client consistency for bulb identity, wear, power settings, activation,
and retained recovery marker, including mounted part replacement on receipt.

## Uncertain-transaction protection — 0.15.5

Before completion validation, the light receives a `lightWorksServiceRecovery`
ModData record. Overlapping actions reject this marker; the owning action can
continue. Commit records the pre-change state and replacement ID. Successful
completion or verified inventory/state rollback clears it. Exceptions, unknown
post-write membership or failed recovery retain `inspection_required`; fresh
actions and reloads must not silently bypass it. No operator repair UI exists yet.

An unknown output presence is not treated as definite insertion failure: no
speculative reinstall/refund follows it. Tests inject reentrant completion,
unknown output state and failed original-item return. Failed validation clears
the temporary lock; a persistent unknown-schema record is never overwritten.
Post-transaction state synchronization is attempted for success and failure.
Native serialization, mounted-part replication, crash durability and operator
reconciliation remain in-game/release gates, not proven by these host tests.

## Wear-state rollback — 0.15.4

The light API owns captureServiceState/restoreServiceState, copying its own
ModData state and recording activation. Recovery reapplies the visible/power
profile without reinstalling a bulb and resetting wear/burnout. Replacement
rollback returns the original consumed item to its original container instead
of manufacturing a same-type replacement. Host tests verify copied custom state,
wear, burnout, activation, original item identity and container no-op rejection.

These operations are internal transaction building blocks, not independently
authorized multiplayer commands. The newer inspection marker contains uncertain
failures but does not automatically repair them. Do not interpret a failed action
as proof that all state was restored.

## Inventory helper hardening — 0.15.2

ItemAccess now verifies ownership and absence after removal. A no-op Remove is
not success. New items are allocated off-inventory so insertion retains an exact
object reference even if AddItem inserts then throws; success requires verified
presence. Notifications follow verified state rather than method return values.
Host tests cover both no-op and throw-after-change behavior, foreign ownership
and failed factories. This does not yet settle unavailable/throwing post-write
membership queries, full bulb wear-state rollback or cross-action concurrency.

The action now loads in shared scope, exposes its global network Type, and
mutates through authority-gated complete. Client perform only cleans up. Complete
rechecks a living actor, item ownership, required tools, bulb availability and
compatibility; each action attempts mutation once, including uncertain failures.
Existing require paths and public class references are preserved.

ItemAccess owns the ownership query: direct/nested inventories and mounted parts
of carried weapons. No world scan is used. In 0.15.3 mounted targets use a
parent-weapon plus exact part-ID constructor payload; the standalone targetItem
field is nil so native serialization does not require a container on the part.
The server reconstructs lightItem from the owned weapon, and completion checks
that the same part remains mounted. Missing, duplicate, swapped and foreign
targets fail closed. Existing four-argument Lua construction remains supported.

Host tests simulate the constructor-name payload and stale identity cases. Actual
network transport and replication of changed part metadata still need hosted and
dedicated testing; this is not a multiplayer compatibility claim.

The host action test mocks transactions and ownership. It proves lifecycle gating,
not complete rollback, native synchronization, or cross-instance replay safety.
Existing rollback logic still requires a full item-state transaction audit.

In game test install/remove/replace, nested/equipped/attached lights, queued item
and tool transfers, cancellation and remote clients. Confirm exactly one mutation
and matching server/client inventory and light state. No multiplayer claim yet.
