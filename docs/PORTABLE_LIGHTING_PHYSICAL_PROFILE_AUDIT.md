# Portable Lighting Physical-Profile Audit

Audit baseline: Project Zomboid 42.20.3 and lightWorks 0.14.0 source before the
physical-metadata pass. Manufacturer figures are engineering analogues, not a
claim that vanilla art depicts those brands. Manufacturer throw is not useful
gameplay range.

## 1. Current implementation summary

lightWorks owns verified light classification, bulb state, servicing, visible
color, beam geometry, UV semantics, attachment presentation, and discovery.
powerWorks owns battery types, stored charge, compatibility, transactions, and
drain. Nightfall consumes lightWorks UV exposure and owns infected consequences.
The colored renderer uses bounded `IsoLightSource` nodes and suppresses the stock
white emitter. Device-specific live emitter profiles already exist. There was no
first-class physical/device reference layer, optical-filter state, cell-count
state, focus state, or technology-driven low-voltage curve.

## 2. Vanilla Build 42 matrix

Values below come from the installed 42.20.3 generated item scripts.

| Item | Distance | Strength | Cone/dot | UseDelta | Weight |
| --- | ---: | ---: | --- | ---: | ---: |
| HandTorch | 15 | 1.8 | cone / .50 | .0060 | .5 |
| Heavy Torch | 25 | 2.0 | cone / .66 | .0070 | 1.0 |
| Angle Head | 15 | 1.5 | cone / .50 | .0060 | .5 |
| Army Angle Head | 15 | 1.5 | cone / .53 | .0057 | .5 |
| PenLight | 11 | 1.2 | cone / .75 | .0010 | .2 |
| Crafted Lantern | 10 | 1.5 | radial | .0070 | 2.0 |
| Crafted Flashlight | 11 | 1.2 | cone / .66 | .0080 | 1.0 |
| GunLight | 15 | 1.3 | cone / .66 | .0010 | .2 |

Vanilla does not encode physical cell size/count in these definitions. GunLight
is a weapon part mountable on the three vanilla pistols.

## 3. Current lightWorks / powerWorks matrix

| Item | Live range/strength/width | Accepted energy item | Drain |
| --- | --- | --- | ---: |
| HandTorch | 12 / .72 / .72 | AA, AA pack, legacy | 1.00 |
| Heavy | 20 / 1.00 / .90 | D, D pack, legacy | .75 |
| Angle | 14 / .78 / .80 | D, D pack, legacy migration | 1.00 |
| Army Angle | 16 / .86 / .72 | D, D pack, legacy migration | 1.00 |
| PenLight | 8 / .46 / .42 | AAA, legacy | .65 |
| Lantern | 7 / .72 / radial | AA, AA pack, legacy | 1.00 |
| Improvised | 9 / .54 / 1.00 | AA, AA pack, legacy | 1.00 |
| GunLight | 11 / .68 / .38 | AA, AA pack, legacy | 1.00 |

Version 0.16.0 with powerWorks 0.7.0 stores independent physical cells in a
versioned set and enforces the declared count. Explicit taped packs remain one
inventory item.

## 4. Real-world counterpart matrix

| Analogue | Source specification | Gameplay use |
| --- | --- | --- |
| Solitaire penlight | 1 AAA, 2 lm, 97 cd, 20 m, 3 h 45 m | 7–10 m inspection light |
| Mini Maglite Xenon 2AA | 2 AA, 14 lm, 2,305 cd, 96 m, 5 h 15 m | 18–25 m baseline |
| Maglite Xenon 2D | 2 D, 27 lm, 10,627 cd, 206 m, 8 h 30 m | 30–40 m heavy thrower |
| Maglite incandescent 2C | 2 C, 31 lm, 12,507 cd, 223 m, 4 h 15 m | alternative heavy reference |
| KPR-102 contractor class | 2.4 V, .7 A, 16.5 lm lamp, 15 h rated lamp life | load/lifetime reference only |

Primary sources: [Maglite Solitaire](https://maglite.com/pages/specifications-solitaire-incan),
[Mini Maglite Xenon 2AA](https://maglite.com/pages/specifications-mini-maglite-xenon-2aa-1),
[Maglite Xenon 2D](https://maglite.com/pages/specifications-maglite-2-d-xenon),
[Maglite incandescent 2C](https://maglite.com/pages/specifications-maglite-2-cell-c-flashlight-incandescent),
[Energizer IN421/KPR-102 engineering sheet](https://data.energizer.com/pdfs/in421.pdf), and
[Energizer alkaline application manual](https://data.energizer.com/pdfs/alkaline_appman.pdf).

## 5. Differences and gaps

- Angle lights currently accept AA; the intended physical profiles call for two D cells.
- Army tactical red is currently an 80/20 red/white bulb spawn, not a white lamp plus filter.
- Multi-cell runtime and migration now require in-game/save/MP validation.
- Runtime is not yet calibrated from energy divided by emitter load.
- Full-charge incandescent color, voltage sag, warm dimming, filters, focus, and spare-lamp storage are absent.
- Gun-light identity remains provisional pending a suitable early-1990s primary source.
- Manufacturer candela/rated throw and useful gameplay range were not explicitly separated.

## 6. Recommended canonical specifications

| Device | Cells | Technology | Useful target | Runtime target | Optics |
| --- | --- | --- | ---: | ---: | --- |
| Penlight | 1 AAA | incandescent | 8 m | 3.75 h | narrow inspection |
| Standard | 2 AA | xenon incandescent | 22 m | 5.25 h | compact adjustable |
| Heavy | 2 D | xenon incandescent | 35 m | 8.5 h | large spot/spill |
| Angle | 2 D | incandescent | 18 m | 9 h | fixed utility |
| Army Angle | 2 D | PR6-style incandescent | 20 m | 9 h | clear/red/blue/diffuser socket |
| GunLight | unresolved | period incandescent | 15 m provisional | unresolved | compact tactical |

These are calibration targets. Existing live geometry remains unchanged until a
5/10/15/20/25/30/40-tile visual tour validates each change.

## 7. Architecture changes actually required

The existing registries should be extended, not replaced. This pass adds
first-class `physical` metadata plus emitter technology, lumens/candela,
color-temperature, rated-throw, useful-range target, and low-voltage behavior.
powerWorks enforces nominal cell count and preserves aggregate absolute energy
through migration. Later work still needs an optical-state component and runtime
calibration; neither is simulated by multiplying drain on one battery item.

## 8. Migration implications

- Preserve all current installed charge during schema migration.
- Convert a legacy installed energy item into a cell set only through an explicit
  deterministic migration, with an equivalent-energy fallback.
- Army red bulbs must remain valid until a migration can produce a white emitter
  plus red filter without deleting bulb condition or charge.
- Unknown/third-party lights retain their verified compatibility record and do
  not inherit guessed cell counts or optics.

## 9. Test plan

For each device test battery insertion/removal/replacement, charge preservation,
bulb service/burnout, beam color/geometry, attachment direction, save/load, and
unsupported-item isolation. Add fixed visual markers at 5, 10, 15, 20, 25, 30,
and 40 tiles. UV adds wavelength, visible-violet presentation, attenuation,
overlap, occlusion, provenance, and authoritative Nightfall consequence tests.
Run one hosted and one dedicated-server persistence/late-join pass before any
multiplayer claim.

## 10. Implementation phases

1. Physical metadata and audit (implemented without live behavior changes).
2. Multi-cell installed-state schema and migration (implemented; live validation pending).
3. Energy/load runtime calibration.
4. Visual beam calibration.
5. Incandescent warm/dim curve at bounded intervals.
6. Optical filters and Army red migration.
7. Focus prototype, retained only if runtime mutation is visually stable.
8. UV wavelength/radiant-output refinement and multiplayer authority validation.
