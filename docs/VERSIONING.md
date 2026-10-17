# Project version inventory

`VERSION` is the sole project SemVer authority. See [VERSION_POLICY.md](VERSION_POLICY.md).
The owner approved adoption of the evidenced `0.25.2` baseline and a compatible
PATCH iteration for the original Spectrum rename/setup. Current MINOR additions,
dependency migration and numeric-angle downgrade limits are described in
FEATURE_COMPLETION.md; the original baseline evidence remains historical.

`version-inventory.json` declares all current mirrors: authoritative `mod.info`,
Lua API version, both authoring-info version lines, README, tester handoff,
current roadmap/testing instructions, current Workshop description/changenote,
repository/validation headers and future current package provenance. Historical
milestones and game/schema/dependency versions are classified independently.

Run before and after every version iteration:

```sh
python scripts/check_versions.py --root .
```

After explicitly authorized packaging, also run:

```sh
python scripts/check_versions.py --root . --release
```

The normal check defers missing `dist/current` outputs; it never certifies an
absent package. `--release` requires the inventoried ZIP, embedded `modversion`,
matching provenance and current changelog. It does not establish gameplay gates.

The preserved local `Contents` tree is a stale legacy snapshot, not a current
mirror. Existing `dist` archives, checksum/upload records and dated research stay
at their actual versions and remain excluded from Git. New packages read only
`src/B47ANCEDSPXTRM` and write only `dist/current`. No historical files are rewritten.

The version checker and policy were copied unchanged from the team's existing
B47ANCEDRooms framework-derived files. Imported byte hashes:

- `scripts/check_versions.py`: `008834561ef6d3321d95d7b9517ad0fde94bd06ff9c1051d0abd79f61659467c`
- `docs/VERSION_POLICY.md`: `80a3c1636b497a516a58875fbbc9b3788e9b216324f4cd6712243af5680db85d`

This records tool provenance, not a newly verified upstream framework revision.
