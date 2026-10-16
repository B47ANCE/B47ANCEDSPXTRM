# lightWorks

lightWorks is the comprehensive lighting and optical-effects framework for the theWorks ecosystem.

- Version: `0.25.2`
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

Project Nightfall registers UV bulbs through this API and consumes lightWorks exposure data for infected-specific consequences. lightWorks never implements Nightfall zombie behavior.
powerWorks behavior reaches registered third-party lights and Nightfall UV lights through lightWorks' canonical light registry.

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

lightWorks was renamed from its pre-release working name because bulbs are now one subsystem within a broader lighting, optical-effects, sunlight, and UV framework.
