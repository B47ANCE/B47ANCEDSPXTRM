# Repository onboarding

Project Version: 0.28.0

Public repository: https://github.com/B47ANCE/B47ANCEDSpectrum

The owner authorized a public repository, adoption of the evidenced `0.25.2`
legacy version and the compatible `0.25.3` rename/setup iteration. The original
source was imported on `main` at
`d6ac13dd47b85ab9aa9a1f4db6db17089204d262`. The rename and tooling are developed on
`chore/b47anced-spectrum-setup` and submitted through a PR before merging main.
No stable-release tag is created. Branch protection/settings are not changed by
this onboarding; the workflow itself does not enforce a protected-main policy.

## Source and preservation

`src/lightWorks` is authoritative, as established by the original README. It
contains 95 files. `Contents/mods/lightWorks` is an older 38-file packaging copy:
57 source files are absent and 13 same-path files differ. Its `modversion` is
`0.25.0`. It is preserved unchanged, ignored by Git and never used to build the
current iteration. These counts describe the pre-rename handoff.

[The legacy ledger](provenance/legacy-0.25.2.json) records exact local source,
packaging-copy, artwork and selected historical artifact hashes. Existing local
archives, backups, checksum/upload records and shared configuration junctions
remain on disk and excluded from the public repository. No cleanup is implied.
The baseline credential scan inspected the 144 selected Git files and found no
suspected secrets. Historical research records are retained without upgrading
their claims or copying third-party mod content.

`SOURCE_INVENTORY.json` declares source ownership, generated outputs, retained
technical identities, dependency and exact translation-folder inventory.
The new root `VERSION`, inventory, checker and policy resolve the legacy absence
of canonical version tracking. See [VERSIONING.md](VERSIONING.md).

## Workflow and boundaries

- Use named branches and PRs; never force-push or rewrite history.
- Run `python scripts/validate.py` and inspect staged diffs before each push.
- Run `python scripts/check_repository.py --staged` after targeted staging.
- Run the shared `Test-PZRepositoryFreshness.ps1 -Repository <repository>` before
  edits/commit/deploy/publish. A dirty result needs interpretation; do not call it
  PASS. Fetch must succeed and affected ancestry must be current.
- CI uses pinned action SHAs, read-only contents permission and no deployment,
  publication, game/server launch, remote diagnostics or automatic cleanup.
- `python scripts/build.py` is an explicit packaging entry point, never part of
  ordinary validation/CI. It refuses nonempty current output, uses source bytes
  and fixed ZIP timestamps, checks paths/collisions/CRC/content, writes SHA-256
  provenance, and runs release-version checks. The command was not executed for
  this rename. Its artifact-generation path remains NOT TESTED.

Runtime remains Lua-only. Python/Lupa are development tools only; no Java/JAR or
native runtime mod dependency was introduced. The original onboarding retained `powerWorks`; the current loader uses
`B47ANCEDPower`. Its repository was inspected read-only for the adapter and an
actual-source host integration probe, without runtime certification. No license grant is invented for the imported project; public source
visibility alone does not establish a reuse license.

## Subsequent thumbnail iteration

The owner-supplied Spectrum artwork replaces the current preview/thumbnail pair.
The original source/artwork ledger and 0.25.3 validation remain historical; see
[ARTWORK.md](ARTWORK.md) and [VALIDATION.md](VALIDATION.md) for current provenance
and evidence. The existing game icon and historical packages are preserved.

## Audit fixes branch

`fix/offline-audit-defects` starts from the thumbnail/setup branch and carries the compatible nine-defect fixes. Its PR targets `chore/b47anced-spectrum-setup` so the fixes can be reviewed separately while the onboarding PR remains open. Neither main merge nor stable release is implied.


## Core features branch

`feature/spectrum-roadmap` starts from `fix/offline-audit-defects` and targets that
branch in a stacked PR. It does not merge the open onboarding/fix PRs. The MINOR
feature iteration and dependency/save-extension decisions are in FEATURE_COMPLETION.md.

## Consumer integration branch

feature/spectrum-consumers starts from feature/spectrum-roadmap (7fd163b) and
uses a stacked PR targeting that branch. It is a 0.27.0 MINOR API/settings
iteration. The user explicitly kept all consumer folders read-only. No consumer
remote, version adoption, source relocation or repository migration is performed
by Spectrum. That iteration observed an external medical Mod ID mismatch, retained in its
validation record. The refreshed pairing now matches; current source preflights
record exact selected source independently from those historical observations.

## Audit and batch-query branch

feature/spectrum-batched-queries starts from feature/spectrum-consumers (79775cd)
and targets that branch with a stacked PR. Version 0.28.0 is a MINOR API addition
plus targeted bug fixes. No open predecessor PR is merged. Historical validation
and supplied artwork stay intact. No deployment, packaging or upload is implied.
