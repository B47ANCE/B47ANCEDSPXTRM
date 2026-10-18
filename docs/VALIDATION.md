# SPXTRM thumbnail validation

Project Version: 0.30.1

2026-10-17 (America/Phoenix). Base b57577372bf2a9004a05e1d224316ff67efff3ce,
public main. PATCH artwork-only change; gameplay/API/save/activation contracts
remain unchanged. VERSION and declared current mirrors are synchronized.

[TESTED, offline Windows] Supplied PNG signature, every chunk CRC, dimensions and
complete file structure pass. Authoring source, preview and mod thumbnail match
the supplied file byte-for-byte by SHA-256; the game icon hash is unchanged.
See ARTWORK.md for exact dimensions, byte count and provenance.

[TESTED, offline Windows] Commands (bundled Python 3.12):

```text
python scripts/check_versions.py
python scripts/validate.py
python scripts/check_repository.py --staged
git diff --check
git diff --cached --check
```

Full existing validation passes: 54 host-Lua regression files, 59 Lua 5.1 syntax
files and disposable Python preflight tests; version, identity, localization,
Lua-only, owned-require case and credential/path checks pass. The only Lua change
is the public project-version constant. No new gameplay regression test is needed.
The exact prior feature-pass report is preserved at validation/0.30.0-feature-pass.md;
its dependency/source observations retain their original tested version/environment.

Feature descriptions and integration contracts are unchanged; no new feature
catalog/overview adoption is part of this artwork patch. Shared catalog/settings
and consumer repositories were not modified.

Freshness: Test-PZRepositoryFreshness.ps1 against this explicit repository before
edits and commit; current main base, no unfinished Git operations. Staged/working
changes are this bounded thumbnail/version/documentation iteration only.

[RUNTIME GATE] In-game thumbnail display and Workshop upload acceptance are NOT
TESTED. Prior native presentation, consumer/runtime, dedicated joins/restarts and
save/reload gates remain unresolved. G7 BLOCKED / NOT TESTED; stable G8 BLOCKED.
No packaging, deployment, game/server launch or Workshop upload.
