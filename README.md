# B47ANCED SPXTRM

B47ANCED SPXTRM is a Lua-only lighting and optical-effects framework for Project Zomboid Build 42.

- Version: `0.30.2`
- Mod ID: `B47ANCEDSPXTRM`
- Author: B47ANCE
- Minimum game version: `42.20.3`
- Required Mod ID: `B47ANCEDPower`

## Features

- Replaceable bulbs for registered flashlights, angle-headed lights, and weapon lights.
- White, red, colored, and extensible emission profiles.
- Tool requirements, timed servicing, persistent bulb state, and burnout.
- Colored portable-light rendering without tinting inventory icons or world models.
- Device-specific beam geometry: compact penlights, standard hand beams, long/strong Heavy-Duty beams, focused weapon lights, angle lights, and radial lanterns.
- First-class 1993 physical-device/emitter metadata separates lumens, candela, rated throw, useful-range targets, optics, technology, and nominal cell design without changing calibrated live beams.
- Tactical spawn distributions, including 80% red / 20% white Army angle-headed lights.
- Realistic attachment profiles: downward belt-light halos and side-facing angle-light cones.
- Automatic candidate discovery with a human-review queue.
- Verified compatibility providers for modded lights.
- Public APIs for light definitions, bulbs, emitters, spectra, sunlight, and UV exposure.
- Required B47ANCEDPower integration for sized cells, charge, and consumption.
- Device-owned pattern selector with server-authoritative owned-item mutation.
- Real vanilla-backed world illumination for active dropped/placed registered
  lights, with persistent identity, orientation, pattern and UV semantics.
- Nearby world lights expose timed Turn On/Turn Off interactions validated by
  the server against exact item identity, position, distance, bulb and charge.
- Active powered world lights expose their real inventory backing through the
  vanilla thump contract so Nightfall can order physical—not simulated—destruction.

Project Nightfall registers UV bulbs through this API and consumes B47ANCED SPXTRM exposure data for infected-specific consequences. B47ANCED SPXTRM never implements Nightfall zombie behavior.
B47ANCEDPower behavior reaches registered third-party lights and Nightfall UV lights through B47ANCED SPXTRM's canonical light registry.

Heavy-Duty Flashlights are intentionally not attachable. Straight Flashlights and Penlights may hang from belts; angle-headed lights may use belts or webbing.

## Documentation

- [Architecture](docs/ARCHITECTURE.md)
- [Testing](docs/TESTING.md)
- [Compatibility policy](docs/LIGHT_COMPATIBILITY_POLICY.md)
- [Roadmap](docs/ROADMAP.md)
- [Build 42 world-emitter audit](docs/WORLD_EMITTER_B42_AUDIT.md)

Debug builds expose `LWStartReleaseSuite()` for automated stack checks followed
by a guided flashlight-by-flashlight visual tour. Each prompt accepts `PASS` or
an issue report and writes the result to `console.txt`.

The authoritative mod source is `src/B47ANCEDSPXTRM/42/`. `Contents/mods` is a preserved packaging copy. Versions use `MAJOR.MINOR.PATCH`; game compatibility is declared separately through `versionMin`.

The display name and activation Mod ID are now B47ANCED SPXTRM / `B47ANCEDSPXTRM`. Enable the new Mod ID on all clients and the server; update Nightfall to the matching dependency iteration. Existing `lightWorks` Lua imports/global, item types, saved fields, sandbox options and network protocol remain compatible. `require "B47ANCEDSPXTRM/API"` and the new global expose the same API table. Workshop item `3788592008` and dependency `B47ANCEDPower` are unchanged. Older builds cannot interpret saved numeric aiming angles. See [identity migration](docs/SPXTRM_MIGRATION.md).

## Development repository

Public source: https://github.com/B47ANCE/B47ANCEDSPXTRM

`VERSION` is the sole project-version authority. This iteration is a
pre-1.0 MINOR activation-ID transition with specialist devices, timed UVC treatment, calibrated model alignment and optical-material contracts. The retained notification API and manual rotation probe remain available. It remains a development build. See [Repository setup](docs/REPOSITORY_SETUP.md),
[Versioning](docs/VERSIONING.md), [Changelog](CHANGELOG.md), and
[Current validation](docs/VALIDATION.md).

With Python 3.12 and the development dependencies installed:

```sh
python -m pip install -r requirements-dev.txt
python scripts/validate.py
```

The Lupa dependency is for offline host tests only. The shipped mod remains Lua
only. CI performs offline checks and never packages, deploys, uploads, or launches
the game. Run `python scripts/build.py` only when packaging is explicitly wanted;
it reads `VERSION` and `src`, refuses nonempty current outputs, and preserves the
legacy `Contents` copy and archives. No package was built for this iteration.

Dedicated multiplayer G7 is **BLOCKED / NOT TESTED**. Stable-release G8 is
**BLOCKED**. Original source/API audits are historical evidence; neither those
records nor host tests establish current PZ runtime behavior.

Current thumbnail: owner-supplied SPXTRM artwork; see [Artwork provenance](docs/ARTWORK.md). The mod icon is the owner-selected transparent flashlight cutout; historical packages are preserved.


The nine defects audited at `886f97d` are corrected in source with offline
regressions: authority-owned burnout and drops, world-energy accounting/retries,
renderer cleanup, replay identity, disabled-pattern demand and incomplete sunburn
samples. See [Audit fixes and dedicated test plan](docs/AUDIT_FIXES.md).


## Current feature completion

- Aim a dropped directional light along your facing, including arbitrary angles.
- Mounted Base.Laser presentation while aiming, with optional visible beam lines.
- Sunburn dose/severity/protection in the local world menu and server-owned
  clothing coverage/holes. Timing remains configurable and provisional.
- Explicit advanced-fixture providers and conservative legacy conversion with
  retained originals and quarantine of conflicts/unknown identities.
- Nearby remote-player colored lights, real-millisecond flicker, bounded
  inventory discovery and boundary-by-boundary optical checks.

See [Feature/API/settings ledger](docs/FEATURE_COMPLETION.md) for ownership,
consumer contracts, migration/downgrade limits and blocked native features.
Source completion and offline tests do not establish PZ runtime correctness.

## Consumer integrations and test preparation

SPXTRM retains two Nightfall stored-bulb aliases and Medical delegation. The matching Health Care 0.11.0 branch adds native timed cold-pack self-care. SPXTRM adds a native timed UVC Water action and purpose-built UVA/UVC/grow-light items with replacement bulbs and configurable contextual loot. Water integration still defaults off and recomputes known powered UVC on the authority. Farming reports optical observations only: crop growth remains unchanged under the user's current scope. All quantities/timing are provisional gameplay values.

See [Consumer contracts/settings](docs/CONSUMER_INTEGRATIONS.md) and
[Current in-game handoff](docs/IN_GAME_TEST_HANDOFF.md). Core Spectrum + Power
passes source preflight. The refreshed Nightfall checkout now requires the matching
B47ANCEDHealthCare Mod ID, so that source profile also passes. The unchanged
medWorks Lua procedure namespace continues to serve the optional API bridge.
Neither source checks nor API presence certify an installed or runtime pairing.

## Current audit and L8 queries

The [0.28.0 audit](docs/AUDIT_0_28_0.md) reproduces and fixes three defects in
prototype debug gating, mutable fixture registration and laser overflow geometry.
New ConsumerExposure.sampleMany and ConsumerIntegrations.cropLightingBatch share
one bounded source scan for up to 32 nearby targets. They return read-only
observations with explicit completeness and paging; they do not change crop growth
or supply cached treatment evidence. Debug mode adds LWIntegrationCropLightingBatch.
Current query contracts and exact limits are in the consumer documentation above.

## Consumer notifications and audit closure

Version-1 [consumer notifications](docs/CONSUMER_NOTIFICATIONS.md) now cover the
owning Spectrum commit boundaries without networking or replaying old events.
Listeners receive independent bounded payloads and cannot cancel completed state;
errors and queue overflow are reported through observer diagnostics. Gameplay
consumers must continue querying and validating authoritative state.

The [audit closure matrix](docs/AUDIT_CLOSURE.md) separates implemented source from
remaining engine evidence and consumer-owned content. [Native presentation gates](docs/NATIVE_PRESENTATION_GATES.md)
record the verified rotation setter/getter route and the guarded SP-only probe.
Default model alignment and production blood redraw remain unverified. Debug
fixture helpers require confirmed debug mode and refuse multiplayer mutations.

## Feature pass 0.30.0

- First-party UVA inspection lamp, UVC service lamp and visible grow lamp; matching bulbs, vanilla housing/icon references, sized-cell profiles and medical/garden loot. No third-party assets imported.
- Timed selected-container UVC treatment rechecks reach, placement, quality and exposure at completion through Water's existing transaction. It changes only biological quality; no claim that the water is safe to drink.
- Opt-in native world-model adapter uses explicit per-item measured north-yaw/sign profiles, verified readback, native complete-item sync and durable recovery. No model has a guessed built-in calibration.
- Bounded material-response registry supplies absorption/fluorescence/reflectance semantics. Native blood redraw remains a debug-only engine gate, not production fluorescence.

[Current feature ledger](docs/FEATURE_PASS_0_30_0.md) records the exact implemented behavior and remaining scope/runtime gates. No package, installation, game/server launch or Workshop upload.
