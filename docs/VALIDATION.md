# Feature iteration validation

Project Version: 0.26.0

Date: 2026-10-16 (America/Phoenix)
Base: eae1e6f (0.25.5). Branch: feature/spectrum-roadmap.

## Source and offline evidence

- [TESTED, offline Windows] Current full validation: 37 host Lua 5.4 regression
  files, 46 Lua 5.1 source/template syntax checks, version/source/localization/path
  and credential checks PASS (197 selected files). Host Lua is not PZ Kahlua.
- [TESTED, offline Windows] Actual local B47ANCEDPower source integration PASS:
  profile registration, canonical precedence, pattern demand, disabled-pattern
  steady demand, world debit and failed-debit checkpoint retention.
  Dependency HEAD 40ff9ebfe247d56d7dd2e308e7b7eabfb61a7ce0; checkout CLEAN.
  Shared Lua tree SHA-256 (sorted relative paths, NUL then bytes):
  a165c3f3262733afc1ea94a8e0ff223df004d5a753db5daecf1c93221073b4c5.
  The first probe observed dirty HEAD 6772aa9 with the same source fingerprint.
  A later probe passed against the now-clean dependency commit above. Neither
  result certifies a deployed pairing. The dependency was read-only and no source was bundled.
- [VERIFIED, installed source] Steam build 25485521; full engine version UNKNOWN.
  Vanilla uses native covered-part/hole APIs, mounted weapon-part lookup, indexed
  projection, UI drawing and activated-mod enumeration. Evidence below records
  source fingerprints, not runtime or dedicated availability guarantees.
- [VERIFIED, history] Exact 0.25.5 validation is retained under
  validation/0.25.5-offline-fixes.md; AUDIT_FIXES.md remains tied to 0.25.5.
- [TESTED, offline Windows] Targeted staged credential/path audit: 133 changed
  files, zero findings. Unstaged/staged whitespace checks PASS. Artwork and
  historical nine-defect records match their exact prior bytes. Remote SHA and
  CI verification are recorded with the PR after commit/push.

## Exact validation commands

Use Python with requirements-dev.txt installed. On the developer machine the
executable used is:
`C:/Users/willi/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe`.

```sh
python scripts/check_versions.py --root .
python scripts/validate.py
python scripts/check_power_integration.py --dependency-root <verified-power-repository>
python scripts/check_repository.py --staged
git diff --check
git diff --cached --check
```

Run the shared Test-PZRepositoryFreshness.ps1 with this explicit repository before
edits and commit. Fetch succeeded on entry: clean HEAD/upstream eae1e6f, 0/0;
main ancestry ahead 3/behind 0. Dirty development REVIEW is not a PASS and must be
interpreted against the intended changes before commit/push.

## API evidence fingerprints

Paths are relative to the installed game. No vanilla bodies are redistributed.

| Evidence | SHA-256 |
| --- | --- |
| media/lua/client/ISUI/ISGarmentUI.lua (43-44, covered regions) | 3188981fb5060afd1c83993a6d2153ebf4ce282227cdab8b8ca8a8ccd95f676f |
| media/lua/shared/TimedActions/ISRepairClothing.lua (26-27, holes) | e5e7a777b2f4b7e10542c16987162cc0710e69d3e66aa2363ac575bb6d58d3c3 |
| media/lua/client/Fishing/TensionUI.lua (11-12, indexed projection) | 6339605e37529c104825325088fe2cd03d7134ee971802b69787b7d397480ab5 |
| media/lua/shared/TimedActions/ISRemoveWeaponUpgrade.lua (15-18, part lookup) | 38dcfe612f8c54e5c721e34399c917750f02861e5ea369e878ad8a9c84db119a |
| media/lua/client/ISUI/ISUIElement.lua (UI draw/input/viewport APIs) | 2de4720f995ae35e76a1465c6690ad17fe272e33dec3b106e49c475310440f8f |
| media/lua/client/ISUI/ISPauseModListUI.lua (19-22, activated-mod list) | 05f83001e8f975c5ee3ea0823ae40384387eceea6d668cda5bbedf22ad72a62c |
| media/scripts/generated/items/weaponpart.txt (113-125, Base.Laser Canon slot) | 30bc0d5c67711d8aa4ae6a9106137dd37779bebef10a5711e9e5e3559de7d2ea |

Read-only class metadata additionally confirms String getPartType and String
getWeaponPart overloads. HandWeapon.class SHA-256:
2d1d3266cd03730fc8af8bfc631eea37a8e07708ceb6fe7b376d2b0e5f4174e4;
WeaponPart.class SHA-256:
c378358d6449cc7b1c2e968420b456a9108c8550246bb29b99a13e7ac69a857a.
Native signatures alone are not Lua invocation proof. Relevant observations were
recorded in the unmanaged local API audit draft with runtime NOT_TESTED.

## Runtime gates and scope

SP and dedicated multiplayer NOT TESTED. G7 BLOCKED / NOT TESTED; stable G8 BLOCKED.
No game/server launched, real-save migration, package, deployment, upload, stable
tag or other-repository write. See TESTING.md for acceptance scenarios and
FEATURE_COMPLETION.md for exact APIs, settings, retained legacy records,
dependency/downgrade limits and external/native blockers. No stable-release claim.
