# Project Zomboid Codex startup

<!-- PZ-CODEX-MANAGED-STARTUP -->
Read the current global rules at C:\Users\willi\.codex\AGENTS.md before work.
Team skills are installed at C:\Users\willi\.agents\skills.
Preserve project-specific identity, instructions, source, local settings and runtime evidence.
<!-- /PZ-CODEX-MANAGED-STARTUP -->

# B47ANCED SPXTRM repository

- Display name: B47ANCED SPXTRM. Technical Mod ID: `B47ANCEDSPXTRM`.
  Retained Lua/item/save/sandbox/protocol namespace: `lightWorks`.
  Required Mod ID: `B47ANCEDPower`; Workshop ID: `3788592008`.
- Authoritative source: `src/B47ANCEDSPXTRM`. Root `Contents` is a preserved stale
  packaging snapshot. Never build from it, overwrite it or delete it implicitly.
- Canonical version: root `VERSION`; see `docs/VERSION_POLICY.md`,
  `docs/VERSIONING.md` and `version-inventory.json`. Current mirrors must match.
- Source/generated inventory: `SOURCE_INVENTORY.json`; historical handoff hashes:
  `docs/provenance/legacy-0.25.2.json`.
- Offline validation: `python scripts/validate.py`; staged audit:
  `python scripts/check_repository.py --staged`. Development setup:
  `python -m pip install -r requirements-dev.txt`.
- Run `python scripts/build.py` only for explicitly requested packaging. It never
  deploys or uploads. Preserve all old archives, snapshots and upload state.
- Keep existing public API, save/config/protocol identifiers and developer
  commands unless a separately authorized compatibility migration is designed.
- Lua-only runtime; server-authoritative gameplay; meaningful shared options
  belong in sandbox settings. New settings require localized labels, supported bounds and server interpretation.
- Use named feature/fix branches and PRs before merging main. No main merge or
  stable tag is implied by a push. No branch protection change without approval.
- G7 remains BLOCKED / NOT TESTED and stable-release G8 BLOCKED until required
  dedicated evidence exists. See `docs/VALIDATION.md`; never relabel old evidence.
