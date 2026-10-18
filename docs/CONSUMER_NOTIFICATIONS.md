# Spectrum consumer notification contract

Project Version: 0.30.2

Artwork-only patch; prior source/offline observations retain their originally
recorded versions. No consumer pairing or PZ runtime evidence was refreshed.
Contract Version: 1

Notifications are bounded, synchronous, process-local advisory invalidations.
They are not commands, durable events, network packets, treatment evidence or an
exactly-once/replay protocol. Server/SP retains all existing gameplay authority.
Clients do not receive the server bus; they continue using existing native/custom
state synchronization and read APIs. No new networking or persisted schema exists.

## Observer API and lifecycle

The public surface is lightWorks.Notifications:

```lua
local token, reason = lightWorks.Notifications.subscribe("pattern", "myMod.lights", function(event)
    -- Invalidate a local cached observation, then query the state owner as needed.
    -- Do not award items, apply effects, issue gameplay intents or change state here.
end)
-- On owner teardown/reload; the token prevents stale teardown removing a successor.
lightWorks.Notifications.unsubscribe("pattern", "myMod.lights", token)
local diagnostics = lightWorks.Notifications.status()
```

Use a namespaced ID (1-128 non-control characters). Each topic/ID is unique;
subscribe returns nil/reason on duplicate, invalid input or the 64-listener cap.
Topic '*' observes all defined topics. Unsubscribe without a token deliberately
removes the current topic/ID; pass the token for safe teardown. It returns false
when missing or when a supplied token belongs to an older registration.

Subscriptions last for the Lua VM or explicit unsubscribe, not a world save.
No old events replay to a late subscriber, joining client or restarted server.
Subscribe and query existing canonical state when attaching. Lifecycle ready
notifications at OnGameStart/OnServerStarted are requery hints, not proof that all
optional mods are available. Those native hooks may both occur in some setups;
no gameplay action may depend on receiving a ready event exactly once.

## Envelope and producer coverage

Every delivered envelope is an independent copied table with contractVersion=1,
sequence (monotonic within this Lua VM), topic, action, side, subject and detail.
Side is server/client/singleplayer when the existing predicates establish it,
otherwise unknown; it is descriptive, never an authorization token. Subject has
kind plus optional opaque id/itemType, without native objects, functions, raw
ModData or inventory/player references. Character IDs can be unavailable in SP.
Do not persist these process-local identities or infer a guaranteed resolvable
entity from them.

| Topic | Actions and boundary |
| --- | --- |
| bulb | serviced after ChangeBulbAction commits and clears its recovery marker; burnedOut after canonical burnout |
| pattern | selected after successful pattern/power-demand change and replay recording |
| world | placed after native drop success; activation after committed switch; depleted after energy checkpoint and existing sync requests |
| orientation | selected after authoritative logical orientation/history update |
| sunburn | updated for meaningful known dose/severity/exposure/protection changes; treated after dose/history commit |
| migration | migrated or quarantined when the canonical receipt changes |
| registry | lightRegistered, bulbRegistered, providerRegistered, providerRemoved through their owning registries |
| sandbox | applied after validated existing settings actually change |
| lifecycle | ready at existing game/server startup hooks |

Rejected/duplicate intents, rolled-back or uncertain service completions, unknown
sunlight/protection intervals and repeated migration receipts emit no false normal
transition. Low-level installBulb/removeBulb/restoreServiceState are transaction
building blocks and deliberately do not notify; their owning completed action
publishes once. Direct native activation, arbitrary table edits and changes owned
entirely by external mods are not covered. Listeners must requery rather than
assume the bus observes every engine or third-party change.

Payload subjects have at most 16 scalar fields with strings <=256 characters;
details have at most 16 scalar fields with strings <=128. Numbers must be finite;
objects, nested data and control strings are rejected. Publishing is internal to
Spectrum producers and omitted from the observer facade. All Lua mods in a VM
remain trusted code; this facade is not a sandbox or security boundary.

## Failure, order and resource limits

Delivery follows subscription registration order. A listener removed before its
turn is skipped; one added during delivery begins with subsequent events. Each
listener gets its own snapshot, and return values cannot cancel the committed
change. Exceptions, including unprintable error objects, are isolated; status
records listenerFailures and a bounded lastFailure rather than rolling back state.
Observers must remain fast and read only; Lua cannot preempt a callback that loops
forever or prevent trusted code from calling unrelated mutation APIs.

Nested publications queue FIFO instead of recursive dispatch. At most 128 events
are drained per dispatch and at most 128 may be queued; excess events are dropped
with a visible diagnostic count. Status reports published, delivered, dropped,
rejected, listeners, sequence and lastFailure. Delivered counts successful callback
invocations, not network acknowledgments. Dropped/failed events require requery;
this bus must never trigger rewards or other non-idempotent gameplay effects.
These are implementation safety limits, not gameplay balance settings.

[TESTED, offline Windows] Snapshot isolation, error handling, subscribe/unsubscribe,
stale-token teardown, 64-listener/128-event budgets, reentrant loops, successful
state boundaries, duplicate/client refusal, service rollback silence and depletion
sync ordering pass. PZ callback scheduling, headless load and reconnect/restart
remain runtime gates. See VALIDATION.md and IN_GAME_TEST_HANDOFF.md.
