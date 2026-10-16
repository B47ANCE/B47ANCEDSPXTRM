# lightWorks Light Compatibility Policy

## Authority levels

- **Verified core:** reviewed vanilla lights shipped by lightWorks.
- **Verified patch:** reviewed lights registered by a separate compatibility mod
  that requires lightWorks and the target flashlight mod.
- **Discovered/review:** ScriptManager metadata identified a likely light. It is
  reported by `lightWorks.LightCatalog` but is not serviceable yet.

Discovery never silently enables bulb replacement. A human-reviewed patch is the
authority that calls `registerLightCompatibilityProvider` and
`registerVerifiedLight` for each exact full item type.

## Automatic interoperability

Once a verified patch is enabled, its registered lights enter the same canonical
lightWorks registry as vanilla lights. Bulbs are registered independently. Thus,
when Project Nightfall is installed, its UV bulbs automatically appear for every
patched light whose optional `accepts` callback permits them. The flashlight patch
does not need a Nightfall dependency or a duplicate UV list.

## Review workflow

1. Enable lightWorks and the target flashlight mod.
2. Let the catalog build after `OnGameStart` or `OnServerStarted`.
3. Print/export `lightWorks.LightCatalog.formatReviewReport()`.
4. Verify each exact full type, visible behavior, attachment/weapon-part state,
   default bulb, tool requirement, and timed-action safety in game.
5. Copy the compatibility template and register only reviewed entries.
6. Set the patch `require=` and `loadModAfter=` fields to lightWorks and the exact
   target mod ID.
7. Retest with Nightfall present to confirm UV bulbs install and emit correctly.

Catalog recommendations are evidence for review, not a compatibility claim.
