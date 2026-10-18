# SPXTRM Workshop test publication

Project Version: 0.30.1

The owner explicitly requested publication on 2026-10-17. This authorizes an update
of existing Workshop item 3788592008, App ID 108600, with current SPXTRM content and
owner-supplied thumbnail. It does not authorize local deployment, game/server launch,
a new item, visibility changes, a main merge, a stable tag or a Steam restart.

Canonical text remains WORKSHOP_DESCRIPTION.txt and WORKSHOP_CHANGE_NOTE.txt;
docs/STEAM_WORKSHOP_DESCRIPTION.txt and workshop.txt mirror the description.
Preparation consolidates repeated feature text below the Steamworks 8,000-byte
description limit (https://partner.steamgames.com/doc/api/ISteamRemoteStorage#k_cchPublishedDocumentDescriptionMax), preserves credits/BBCode, corrects stale activation and absent-UVC claims and explicitly records
native presentation, consumer and dedicated test limitations. This is a documentation
checkpoint within the existing PATCH artwork iteration, with no gameplay change.

Build with `python scripts/build.py` from authoritative src/B47ANCEDSPXTRM, never
root Contents. It preserves prior outputs, generates dist/current with deterministic
ZIP and per-member SHA-256 provenance, and runs `python scripts/check_versions.py
--release`. Validate CRC, paths, duplicate/case collisions, exact staging hashes,
Lua-only content and the exact thumbnail. Record the final clean public source
commit, archive hash, game source build 25485521 (running engine version UNKNOWN),
IDs, validation and VDF/staging hashes in the ignored distribution manifest before
upload. Retain the old local ZIP, backups and legacy VDF unchanged for recovery.
Historical lightWorks packages use the old Mod ID and are not a compatible rollback
promise for changed enabled-mod lists; use disposable test saves and retain backups.

The original local SteamCMD VDF is under Zomboid/Workshop/_steamcmd/lightWorks.vdf;
it points to stale source and serializes literal newline escapes. Preserve it as
history. Create an isolated submission under dist/workshop-publish for the current
verified archive, content folder, preview and current reviewed text. Omit the VDF
visibility field to preserve the item's existing visibility. Use the verified local
SteamCMD executable and existing cached account; never place authentication secrets
in source, VDFs or reports. No wrapper or submission step restarts Steam.

Missing dedicated evidence permits only a labelled Workshop MP test upload under
the shared WORKSHOP_MP_TESTING policy. G7 BLOCKED / NOT TESTED; stable G8 BLOCKED.
SteamCMD must explicitly confirm success for item 3788592008. Upload is distribution
evidence only. Public-page/API verification may be unavailable; record that gap.
After success ask separately before restarting Steam, then humans test subscription,
startup, client join/rejoin, state synchronization, persistence and server restart.
Actual result and exact hashes belong in the ignored per-publication manifest/log;
this document records preparation, not a claim that upload already succeeded.
