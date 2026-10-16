# Spectrum thumbnail

The owner supplied and explicitly selected this image on 2026-10-16.
`artwork/spectrum-thumbnail.png` is the authoritative full-resolution PNG.
The existing project thumbnail and Workshop preview form a matching pair:

| Role | File |
| --- | --- |
| Authoring source | `artwork/spectrum-thumbnail.png` |
| Workshop preview | `preview.png` |
| Existing mod thumbnail/poster reference | `src/lightWorks/thumbnail.png` |

All three contain the exact supplied bytes: 1254 x 1254 RGB PNG, 1,559,539 bytes,
SHA-256 `44e03c1e64fd9bdcbbf767b81ec3f08850c00dcb4e3709e9f374046e34eea119`.
No AI regeneration, crop, resize or color conversion was applied. Artwork was
supplied for project use; no broader license grant is inferred.

The 32 x 32 RGBA game icon at `src/lightWorks/42/icon.png` is unchanged.
The previous preview and thumbnail are recoverable from commit
`886f97d449de192a778dc241157948b5f9cf2214`, and legacy local packages retain their
original artwork. The legacy provenance ledger still describes the original
handoff bytes; it is not a checksum list for newly replaced current artwork.

The build command already reads `preview.png` and `src/lightWorks`; no packaging
script change is needed. No package was generated and no live Workshop metadata
or preview was uploaded. Upload acceptance and in-game display remain untested.
