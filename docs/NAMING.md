# B47ANCED Spectrum identity

The public display name is **B47ANCED Spectrum**, formerly lightWorks. This is
a compatible branding change, not a new mod or a persistence migration.

| Surface | Identity |
| --- | --- |
| Display name, sandbox page, Workshop title | B47ANCED Spectrum |
| Public repository | B47ANCE/B47ANCEDSpectrum |
| Mod ID, installed mod folder, source folder | `lightWorks` |
| Lua global and require namespace | `lightWorks` |
| Item ModData, sandbox keys, network command module | Existing `lightWorks` identifiers |
| Developer commands and report filename | Existing `LW*`, `lightWorksTest*`, and legacy report path |
| Required dependency | `B47ANCEDPower` (migrated in 0.26.0) |
| Existing Workshop item | `3788592008` |

Consumers such as Project Nightfall and medWorks continue to call the same API.
Servers keep the same Mod ID and sandbox keys. No existing saved state is moved,
duplicated, reset or reinterpreted. No new shared state or configuration setting
is needed for a display-name change. Existing internal limits remain internal.

Current docs use the Spectrum display name; source filenames, API examples and
dated evidence retain their exact technical/historical names. Manually supplied
game icon remains unchanged. The owner-supplied Spectrum image now fills the current thumbnail/preview pair; see [ARTWORK.md](ARTWORK.md). Historical artwork remains in Git. Local deployment and the live
Workshop title remain unchanged until separately authorized.

The display-name-only guarantees above describe the original rename. Current
feature/dependency and save-extension changes are documented in FEATURE_COMPLETION.md.
