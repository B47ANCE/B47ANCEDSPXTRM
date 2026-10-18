# SPXTRM thumbnail

The owner supplied and explicitly selected this replacement image on 2026-10-17.
`artwork/spectrum-thumbnail.png` remains the authoritative full-resolution PNG;
the established filename is retained. The text in this image reads SPXTRM.

| Role | File |
| --- | --- |
| Authoring source | `artwork/spectrum-thumbnail.png` |
| Workshop preview | `preview.png` |
| Existing mod thumbnail/poster reference | `src/B47ANCEDSPXTRM/thumbnail.png` |

All three contain the exact supplied bytes: 1254 x 1254 PNG, 1,483,761 bytes,
SHA-256 `34bea63dd537f1236471b29e47e73f17d866b7f35086c669a8e3f0baabca72d7`.
No regeneration, crop, resize or color conversion was applied. Artwork was
supplied for project use; no broader license grant is inferred.

The thumbnail remains unchanged in 0.30.2. The previous
Spectrum-lettered artwork remains recoverable from parent commit
`b57577372bf2a9004a05e1d224316ff67efff3ce`; older artwork remains in Git history
and historical local packages. No historical source/package/evidence was replaced.

The build command already reads `preview.png` and `src/B47ANCEDSPXTRM`; no packaging
script change is needed. The prior 0.30.1 package was uploaded through SteamCMD with confirmed success;
public-page/preview verification was unavailable. That is distribution evidence,
not in-game display or dedicated verification. Current upload evidence belongs to
the exact version/commit manifest under ignored dist/workshop-publish.

## Transparent mod icon (0.30.2)

The owner explicitly selected the generated single-flashlight cutout on 2026-10-18.
Master: `artwork/spxtrm-icon-master.png` (1254x1254 RGBA); exact built-in image_gen
prompt: `artwork/spxtrm-icon-prompt.txt`. This is derived from the owner-supplied
thumbnail; no broader license/third-party asset reuse is inferred.

Export: `src/B47ANCEDSPXTRM/42/icon.png` (64x64 RGBA, real alpha), using
System.Drawing high-quality bicubic downsampling only. No text, additional lights,
beams or background fill. Exact source/export hashes are in SOURCE_INVENTORY.json.
The prior 32x32 icon remains recoverable from 0.30.1 Git/package history.

[VERIFIED, installed source] Build 25485521 ModListBox.lua lines 200-201 loads the
configured icon and scales it into BUTTON_HGT; this export does not change layout
or mod.info icon/poster references. [TESTED, offline] Dimensions, alpha/corners,
PNG decode, source and export hashes checked; exported icon visually inspected.
[RUNTIME GATE] In-game icon display is NOT TESTED. No local install or launch.

The three supplied thumbnail PNGs retain SHA-256
`34bea63dd537f1236471b29e47e73f17d866b7f35086c669a8e3f0baabca72d7`.
Workshop publication reuses the exact previously uploaded quality-95 JPEG derivative
(SHA and bytes verified from the retained 0.30.1 manifest), preserving its preview.
