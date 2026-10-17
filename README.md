# B47ANCED Spectrum

B47ANCED Spectrum is a Lua-only lighting and optical-effects framework for Project Zomboid Build 42.

- Version: `0.29.0`
- Mod ID: `lightWorks`
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

Project Nightfall registers UV bulbs through this API and consumes B47ANCED Spectrum exposure data for infected-specific consequences. B47ANCED Spectrum never implements Nightfall zombie behavior.
B47ANCEDPower behavior reaches registered third-party lights and Nightfall UV lights through B47ANCED Spectrum's canonical light registry.

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

The authoritative mod source is `src/lightWorks/42/`. `Contents/mods` is a preserved packaging copy. Versions use `MAJOR.MINOR.PATCH`; game compatibility is declared separately through `versionMin`.

The display name is B47ANCED Spectrum. The technical Mod ID, Lua API/require namespace, save fields, sandbox option identifiers and network command module remain `lightWorks` to preserve existing integrations. The required dependency is now `B47ANCEDPower`; the Workshop item remains `3788592008`. Update the dependency and all clients/server together. Older clients cannot interpret saved numeric aiming angles.

## Development repository

Public source: https://github.com/B47ANCE/B47ANCEDSpectrum

`VERSION` is the sole project-version authority. This iteration is a
MINOR notification iteration with post-commit consumer invalidations,
read-only observation hardening and a manual native model-rotation probe. It remains a development build. See [Repository setup](docs/REPOSITORY_SETUP.md),
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

Current thumbnail: owner-supplied Spectrum artwork; see [Artwork provenance](docs/ARTWORK.md). The game icon and historical packages are preserved.


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

Spectrum owns two explicit Nightfall stored-bulb aliases, delegates the existing
Medical procedure, registers an optional UVC-only Water quality treatment, and
reports read-only Farming illumination. No consumer files are edited. Water's
sandbox opt-in defaults off; Nightfall bulbs use UVA and cannot trigger it. No
UVC device, treatment action or crop growth effect is invented.

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
