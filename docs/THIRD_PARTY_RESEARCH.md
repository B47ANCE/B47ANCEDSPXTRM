# Legacy interoperability provenance

Scope: independent known-record conversion into Spectrum, not reuse of a legacy
implementation. The existing EXT-35 audit in BULBWORKS_MIGRATION_AUDIT.md supplies
the neutral identifier/field contract. No external mod source, asset or private
save was reopened or copied during this iteration.

- Legacy title/version: Bulbworks 42.20.3-0.4.0-0, as recorded by the dated audit.
- Author, source URL, Workshop ID and license/permissions: UNKNOWN in the supplied
  evidence. No right to copy implementation/assets is inferred.
- Historical audited API fingerprint:
  C2798170ED4981E94DB2D13234EF01EC9FCD2E8D7CA89EB78BDF6C21F6DE2E5F.
- Observation used: legacy ModData field names, units, explicit empty/installed
  states, old identifiers and competing-runtime conflict. No definitions,
  balances, registry content, algorithms, textures, translations or code imported.
- Original design: one bounded authority entry point, strict scalar validation,
  original-record retention, explicit owner alias registration, conservative
  conflict/unknown quarantine, a versioned receipt and existing native sync.
- Nightfall alias ownership is unresolved; obsolete IDs are retained/quarantined.
  No corresponding external consumer code is changed.

Clean-room checklist: neutral contract only; imported third-party code/assets NONE;
original implementation and synthetic tests; unknown rights remain explicit.
Independent reviewer signoff is PENDING on the PR before merge; offline technical
tests are not legal clearance or that signoff. No third-party attribution notice
is removed. No redistributable component is bundled.

B47ANCEDPower is a separate first-party dependency. It was read-only, not copied or
edited; its current source fingerprint and observed checkout states are in VALIDATION.md.
