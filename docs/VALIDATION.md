# Spectrum thumbnail validation

Project Version: 0.25.4

Date: 2026-10-16 (America/Phoenix)

Scope: owner-supplied thumbnail/preview replacement and synchronized version
metadata. No gameplay fix is included. The audit findings against 886f97d remain
unresolved; no previous runtime evidence is upgraded by this artwork change.

## Current evidence

- [TESTED, offline Windows] Original PNG structurally verified: 1254 x 1254, RGB,
  1,559,539 bytes. All three current copies have identical SHA-256
  `44e03c1e64fd9bdcbbf767b81ec3f08850c00dcb4e3709e9f374046e34eea119`.
- [VERIFIED, visual] The supplied artwork shows the Spectrum title, three lights
  and spare bulbs. It is used unchanged, with no resize, crop or regeneration.
- [TESTED, offline Windows] Existing game icon remains byte-identical at SHA-256
  `ee7351b8932db9969c20344c7328de4281292c5b9896ae3ee3ea32906b8159ef`.
- [TESTED, offline Windows] Version inventory passed at 0.25.3 before the update.
  Current version/repository checks PASS at 0.25.4 (165 selected files; zero
  credential/path findings). The staged audit and whitespace checks also PASS.
- [VERIFIED, history] The previous validation file is preserved unchanged at
  [0.25.3-rename.md](validation/0.25.3-rename.md). Its original-artwork and test
  claims apply to that historical iteration only.

## Commands

```sh
python scripts/check_versions.py --root .
python scripts/check_repository.py
python scripts/check_repository.py --staged
git diff --check
git diff --cached --check
```

On this machine, `python` is invoked through the bundled executable at
`C:/Users/willi/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe`.
The artwork check uses Pillow to verify PNG structure, dimensions and RGB mode;
SHA-256 compares the authoritative source and both current thumbnail slots.
CI's existing offline suite also runs Lua syntax/regressions; none is a PZ
runtime test or evidence that the known gameplay defects have been repaired.

## Gates and limits

SP and dedicated multiplayer: NOT TESTED for this iteration. G7 remains
BLOCKED / NOT TESTED; stable-release G8 remains BLOCKED. The existing authority,
world-light accounting/cleanup, replay, pattern and sunburn defects remain open.
No game/server launch, package, local deployment or Workshop upload occurred.
The full-size supplied PNG is retained exactly; Workshop upload acceptance and
in-game thumbnail display have not been tested. Historical packages and their
artwork remain unchanged.
