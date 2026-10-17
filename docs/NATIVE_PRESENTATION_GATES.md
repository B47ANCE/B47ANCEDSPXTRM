# Native presentation evidence and runtime gates

Project Version: 0.30.0
Steam build: 25485521. Full engine version: UNKNOWN.

## World-model yaw: source route verified, alignment untested

[VERIFIED, installed vanilla Lua] ISDropWorldItemAction.complete obtains the placed
InventoryItem, calls setWorldZRotation, and then transmits its complete world
backing. ISExtendedPlacementUI obtains the inventory item from its world object,
reads original X/Y/Z rotations and assigns numeric rotations from its gizmo.
These are observed Lua receivers/calls, not a guessed method name.

[VERIFIED, native metadata only] InventoryItem declares public setWorldZRotation
with descriptor (F)V and getWorldZRotation ()F. The exact portable source hashes,
observed ranges and limitations are in validation/api-evidence-25485521.json.
Class metadata/digests are in validation/native-metadata-25485521.json. No game
source bodies, classes, assets or JAR are bundled or modified.

This supersedes the earlier blanket 'no verified Lua contract' statement for the
setter. It does not establish a model's zero direction, sign, offset, tilt, render
refresh or multiplayer serialization behavior. Spectrum therefore retains native
model placement and makes no default mapping from logical beam direction to model
yaw. Arbitrary-angle beam geometry remains implemented independently.

## Manual SP debug probe

After a separately authorized deployment, use a disposable save and one exact,
nearby registered placed-light InventoryItem (within three tiles, same floor).
Get it through the existing inspected world backing's getItem, not by a guessed ID.
Only explicit calls change a native field:

```lua
LWModelRotationInspect(item)
LWModelRotationPreview(item, 90)
LWModelRotationStatus()
LWModelRotationRestore() -- exact tracked preview; optional explicit item argument
```

The module is inert without positively confirmed debug mode. It refuses all
multiplayer/server contexts, unknown/mismatched backing, invalid yaw and remote
fixtures. Only one preview may be active. It preserves the original yaw, never
changes X/Y rotation, logical orientation, light state, power or ModData, and
checks native readback with a 0.001-degree tolerance. Preview errors attempt and
verify restoration; unverified restore remains inspection_required and blocks
replacement previews. Removal of the exact backing attempts restoration. An owned
picked-up item can also be restored; status remains available if native reads fail.
Do not use this on real saves or assume a crash restores a native field. Restore
explicitly before leaving the test. Rollback is the disposable-save backup.

Acceptance: record native getter/preview/readback/original for 0/90/180/270 and
arbitrary angles; inspect each model against logical light/UV geometry. Verify
pickup/drop, render refresh and reload. Determine per-model mapping explicitly
before any production adapter. Dedicated sync cannot be certified by this SP-only
probe; a separately designed authoritative adapter and two-client evidence remain
required before changing default native model behavior.

## Native blood/FBO rendering: still a runtime/source gate

[UNKNOWN, Lua invocation] IsoSprite has a public native renderBloodSplat declaration
(FFFLzombie/core/textures/ColorInfo;)V, but that declaration alone does not verify
Lua dispatch or the correct FBO/depth stage. No current supported arbitrary shader
route was established. The existing LWUVBloodTest spike remains debug-only, manual,
and non-production. It intentionally tests native redraw before connecting UV.

Acceptance: on a disposable SP save, with confirmed debug mode, compare absorption
and diagnostic fluorescence against walls, characters, vehicles, different floors,
zoom, occlusion and unloaded chunks; record rendered/missing/error counters. The
sample-placement helper is SP-only and persistent, so prefer existing disposable
blood samples and never use a real save. Compare render-hook stage and visibility.
Do not claim fluorescence or activate production overlays from source signatures
or a host stub. Registered purpose-made overlay assets remain a Lua-only design
alternative; they are not supplied or substituted for unverified native blood.

## Reproduce source inspection

```sh
python scripts/inspect_native_metadata.py --game-root <verified-game-root>
```

The tool reads declared method metadata from the installed JAR with Python only;
inherited methods are omitted and absence from its list is not an absence claim.
It neither executes nor extracts game code. Matching hashes establish inspected
bytes, never runtime behavior. API findings were also recorded with pz-api-audit
in the unmanaged local library; installed managed catalogs were not modified.

No custom Java/JAR/bridge code, deployment, game/server launch or publication.
SP NOT TESTED; dedicated G7 BLOCKED / NOT TESTED; stable G8 BLOCKED.

## 0.30.0 calibrated production adapter

ModelAlignment now supplies optional authority-owned application/readback/sync/recovery for explicitly calibrated items. Register exact measured northYaw/sign and evidenceId; EnableNativeModelAlignment defaults false. No model mapping is guessed. Failed/unproved restore retains lightWorksNativeModelRecovery until explicit verified restore. This implements the adapter, not its missing model calibration or runtime certification. ReactiveMaterials supplies the optical response semantics; native blood remains debug-only and blocked as above.
