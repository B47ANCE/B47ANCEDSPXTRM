# UV obstruction adapter

Repository-only `lightWorks_UVOcclusion.trace(cell, source, target, policy)` returns
a transmission fraction and reason, or nil/reason when facts are unavailable.
It now feeds `UV.getOccludedArtificialExposure(entity, emitters, context)` and
does not fix rendered light bleeding by itself. Source/target contain finite
x/y/z coordinates. The legacy two-argument exposure API remains unchanged until
Nightfall migrates its damage consumer.

The new API aggregates only transmitted contributions, preserving spectrum and
source details with transmission/unoccluded intensity diagnostics. Its result
reports `uv.complete`, `occlusionChecked`, `checkedSources`, `blockedSources` and
`unknownSources`. Missing geometry or policy sets complete=false: consumers must
not interpret a partial sum as a fully evaluated exposure interval. A 64-emitter
budget bounds ray work and flags over-budget batches incomplete rather than
silently dropping excess light. This is a processing limit, not a biological UV
dose cap. Supply `context.cell` or use the current cell, plus explicit window
transmission where applicable. No dose/health mutations occur in lightWorks.

`UV.getVerifiedExposure(entity, emitters, context)` now combines sunlight with
obstruction-checked artificial UV. `uv.complete` requires both halves to be known.
Missing outdoor climate data, an unreadable square or failed exposure modifier is
incomplete, not verified darkness. Legitimate zero daylight and verified indoor
zero sunlight remain valid samples. The existing sunlight numeric result remains
available for legacy consumers; new tissue consumers must check completeness.

Strict samples also report malformed emitters as incomplete, distinguishing an
unreadable source from a verified zero-output, out-of-range or other-floor source.
Invalid spectral tables/band values and arithmetic overflow cannot inject NaN or
infinity into accumulated exposure. Rejected contributions are counted as unknown
and excluded from numeric totals; those partial totals must not advance tissue
dose. Host coverage includes malformed mod emitters and spectral overflow.

The bounded grid traversal calls installed `IsoGridSquare.testVisionAdjacent`
with diagonal checks enabled and door ignoring disabled. Native implementation
inspection confirms special-object handling for doors, windows, curtains and
barricades. Blocked and closed-door paths transmit zero; open-door paths can pass.
Unknown native results, missing squares and unavailable APIs return unknown,
never assumed clearance. Cross-floor paths transmit zero. Traversal is capped
at 128 grid crossings without scanning global objects.

Windows require explicit `policy.windowTransmission` in [0,1]; visible clearance
alone does not establish UV transmission. A fraction multiplies per encountered
window result. Native vision may combine diagonal boundaries into one result;
window count/material precision and broken-versus-intact glass need further
inspection before spectral attenuation is considered physically accurate.

Tests exercise bounded cardinal/diagonal/reverse paths, walls, closed/open doors,
explicit window transmission, unknown results, missing squares, floors and invalid
inputs. Native curtain/barricade behavior was inspected but is not simulated in
the current host tests. In-game obstruction acceptance and renderer floor bleed
remain open. No cache is installed, so closed/open state cannot become stale in
this adapter; the eventual exposure scheduler must budget ray calls.
