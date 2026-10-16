# UV-Reactive Materials Feasibility

Research date: 2026-08-23  
Target runtime: Project Zomboid 42.20.3

## Conclusion

UV-reactive world materials are plausible as a lightWorks subsystem, but not as
a universal shader effect through the currently exposed Lua API.

- Native floor and wall blood can be discovered safely and locally.
- Native blood geometry can probably be redrawn with altered color/contrast.
- Custom lightWorks-aware items and world objects can support reliable UV-only
  overlay sprites.
- Arbitrary clothing, character models, and third-party textures cannot be given
  true fluorescence generically without a renderer hook or purpose-made overlays.
- The Build 42 FBO render order must be proven in game before production work.

Overall feasibility: **high for blood decals and registered custom assets,
medium for corpses/clothing, low for arbitrary vanilla or modded textures.**

## Real-world behavior

Fluorescence is wavelength-dependent and surface-dependent. A material absorbs
shorter-wavelength excitation and emits longer-wavelength visible light. Many
forensic alternate-light-source workflows also use barrier filters to suppress
reflected excitation light.

### Blood

Untreated whole blood should not glow like fluorescent paint. NIJ's alternate
light source review describes untreated blood primarily as an absorption target.
Violet/near-UV illumination can increase contrast, especially on dark or patterned
surfaces. Blood serum and plasma can be detected at 365 nm more effectively than
at 395 nm. Luminol is a separate chemical reaction: hemoglobin catalyzes a
temporary blue-green chemiluminescence, and bleach/copper can produce false
positives.

Recommended simulation:

- Fresh untreated blood: subtle darkening/contrast under violet or UV.
- Dried untreated blood: stronger absorption contrast, never a neon glow.
- Serum edge/transfer residue: faint cool fluorescence under a high-quality
  365 nm source.
- Luminol-treated blood: temporary blue-green emission visible in darkness,
  independent of continued UV illumination.
- Washed blood: reduced visual response; chemical treatment may still reveal it.

### Other defensible reactions

- Bone and teeth: visible fluorescence is well supported; violet 395–425 nm and
  blue light can aid recovery, with response affected by dirt and condition.
- Laundered fabric: optical brighteners deposited by detergents can fluoresce;
  intensity and spectrum depend on detergent, fiber, and washing history.
- Semen and urine: can fluoresce, especially on cloth, but response varies and
  can be faint; they should be clues rather than guaranteed identification.
- Saliva, sweat, fingermarks, fibers, lubricants, and moisturizers: possible
  alternate-light responses, but wavelength, substrate, age, and false positives
  matter. A UV reaction must never be treated as proof of material identity.

## Verified Build 42.20.3 surfaces

The installed `projectzomboid.jar` was inspected directly.

### Floor blood

`IsoChunk.floorBloodSplats` is a public `BoundedQueue`. The queue exposes public
`size()` and `get(index)` methods. Each `IsoFloorBloodSplat` exposes public:

- `x`, `y`, and `z`;
- `type` and `index`;
- `worldAge` and `fade`;
- owning `chunk`;
- static `spriteMap` and `FLOOR_BLOOD_TYPES`.

This permits a bounded scan of only the chunks intersecting active UV emitters.
No cell-wide or world-wide scan is needed.

### Wall blood

`IsoObject.wallBloodSplats` is a public list. Each `IsoWallBloodSplat` exposes its
`worldAge`, native `sprite`, orientation tests, and a public render method.
lightWorks can inspect only objects on squares within active UV ranges.

### Rendering

`IsoSprite.renderBloodSplat(x, y, z, ColorInfo)` is public. The native floor-blood
sprite can therefore be resolved from the splat type and submitted with a
reaction color. Wall splats expose their own public `render(...)` path.

The engine does not expose a general Lua material shader that can modify only the
blood pixels already present in the completed scene. Direct redraw must be tested
against Build 42's FBO/depth render order. If it draws above characters or walls,
production rendering will require registered overlay sprites or a Java-level
render hook.

`IsoObject` also exposes overlay sprites, attached sprites, custom color, and
per-player highlighting. These are suitable for lightWorks-aware objects but are
too coarse for generic blood: custom color tints an entire object, and a grid
marker does not preserve splat shape.

## Proposed ownership and API

lightWorks should own generic excitation and visible reaction semantics:

```lua
lightWorks.registerUVReactiveMaterial({
    id = "Base.UntreatedBlood",
    target = "floor-blood",
    excitation = { minNm=365, maxNm=425 },
    response = "absorption",
    color = { r=0.12, g=0.02, b=0.03 },
    intensity = 0.35,
    requiresFilter = false,
})
```

The registry should distinguish:

- `absorption`: darkens or increases contrast;
- `fluorescence`: emits a longer-wavelength visible overlay while excited;
- `chemiluminescence`: time-limited emission caused by a chemical treatment;
- `reflectance`: changes apparent contrast without claiming fluorescence.

Nightfall may register altered infected fluids through this API. It should not
own generic blood discovery or rendering. medWorks may later own luminol use,
sample collection, cleaning, and medical/forensic procedures.

## Performance design

1. Collect active lightWorks UV emitters already known to the exposure system.
2. Compute intersecting chunk coordinates from emitter position and range.
3. Inspect each unique loaded chunk once per throttled update.
4. Filter floor splats by squared distance, level, cone, and optional occlusion.
5. Inspect wall-blood lists only on nearby squares/objects.
6. Cache visible reactions by splat identity/index until the emitter or chunk
   changes.
7. Render only cached reactions each frame.

The system must have independent scan and render budgets and degrade by skipping
distant/weak reactions rather than stalling gameplay.

## Required technical spike

Before committing the feature:

1. Place known floor and wall blood in a dark test room.
2. Resolve the native floor sprite from `spriteMap` and `type`.
3. Redraw one splat through `renderBloodSplat` during candidate render events.
4. Verify floor depth, wall orientation, cutaways, zoom, multiple Z levels, and
   split-screen ownership.
5. Test absorption colors and emissive-looking colors separately.
6. Confirm overlays disappear immediately when UV is off or occluded.
7. Measure 10, 100, 500, and 1,000 nearby splats.
8. Confirm save/load does not duplicate or mutate native blood state.

Go/no-go rule:

- If native redraw respects scene depth, implement blood reactions without new
  artwork.
- If it does not, support only registered UV-overlay assets until a safe render
  hook exists. Do not replace or permanently recolor vanilla blood.

## Research sources

- NIJ, *Landscape Study of Alternate Light Sources*:
  https://www.ojp.gov/pdffiles1/nij/grants/251492.pdf
- NIJ, *Locating DNA Evidence* (alternate light and luminol cautions):
  https://nij.ojp.gov/nij-hosted-online-training-courses/collecting-dna-evidence-at-property-crime-scenes/crime-scenes/locating-evidence
- Kearse, *Ultraviolet 365 as an Alternative Light Source for Detection of Blood Serum*:
  https://pubmed.ncbi.nlm.nih.gov/32343369/
- James, *Detection of latent bloodstains on fabric using an ALS*:
  https://pubmed.ncbi.nlm.nih.gov/33284461/
- van Dam et al., *Specific fluorescent signatures for body fluid identification*:
  https://pubmed.ncbi.nlm.nih.gov/36823309/
- Sterzik et al., biological traces on different materials:
  https://pubmed.ncbi.nlm.nih.gov/26500091/
- Lee et al., detergent fluorescence on textile fibers:
  https://pubmed.ncbi.nlm.nih.gov/26647148/
- Alternate-light skeletal-remains field study:
  https://pmc.ncbi.nlm.nih.gov/articles/PMC12223349/
- Installed 42.20.3 `projectzomboid.jar`: `IsoChunk`,
  `IsoFloorBloodSplat`, `IsoWallBloodSplat`, `IsoObject`, and `IsoSprite`.
