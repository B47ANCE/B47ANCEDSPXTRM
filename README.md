# B47ANCED Spectrum

B47ANCED Spectrum is a Lua-only lighting and optical-effects framework for Project Zomboid Build 42.

- Version: `0.25.5`
- Mod ID: `lightWorks`
- Author: B47ANCE
- Minimum game version: `42.20.3`
- Required Mod ID: `powerWorks`

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
- Required powerWorks integration for sized cells, charge, and consumption.
- Device-owned pattern selector with server-authoritative owned-item mutation.
- Real vanilla-backed world illumination for active dropped/placed registered
  lights, with persistent identity, orientation, pattern and UV semantics.
- Nearby world lights expose timed Turn On/Turn Off interactions validated by
  the server against exact item identity, position, distance, bulb and charge.
- Active powered world lights expose their real inventory backing through the
  vanilla thump contract so Nightfall can order physical—not simulated—destruction.

Project Nightfall registers UV bulbs through this API and consumes B47ANCED Spectrum exposure data for infected-specific consequences. B47ANCED Spectrum never implements Nightfall zombie behavior.
powerWorks behavior reaches registered third-party lights and Nightfall UV lights through B47ANCED Spectrum's canonical light registry.

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

The display name is B47ANCED Spectrum. The technical Mod ID, Lua API/require namespace, save fields, sandbox option identifiers and network command module remain `lightWorks` to preserve existing integrations. The required `powerWorks` Mod ID and Workshop item `3788592008` are unchanged.

## Development repository

Public source: https://github.com/B47ANCE/B47ANCEDSpectrum

`VERSION` is the sole project-version authority. This iteration is a compatible
PATCH fix for the nine offline-reproduced audit defects; it preserves the public
API/save/configuration contracts and does not claim a stable release. See [Repository setup](docs/REPOSITORY_SETUP.md),
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
