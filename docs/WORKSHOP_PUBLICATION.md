# SPXTRM Workshop test publication

Project Version: 0.30.2

The owner explicitly requested the new mod icon, unchanged thumbnail, merge of
all SPXTRM open PRs after checks and publication on 2026-10-18. Existing PR #8 is
merged after passing checks; submit/merge the icon PR after its CI passes. Build
and upload from the exact clean merged public main SHA. No stable tag is implied.

Canonical text remains WORKSHOP_DESCRIPTION.txt and WORKSHOP_CHANGE_NOTE.txt;
docs/STEAM_WORKSHOP_DESCRIPTION.txt and workshop.txt mirror the description.
A pre-upload API review found live page edits: the display title differs from
source, and the inline banner and long test-status footer had been removed.
Preserve those live edits, mirror the live description with the current version
and a compact required test-status notice, and omit title from the VDF. Mod
identity/display metadata are unchanged by this publication checkpoint. Description
uses real line breaks, preserves credits and is below the Steamworks 8000-byte
limit. Both texts retain MP testing build - dedicated multiplayer NOT TESTED.

Reuse scripts/build.py for authoritative src/B47ANCEDSPXTRM. Never build from or
overwrite historical root Contents. Prior current ZIP/provenance are preserved
with verified hashes under dist/release-backups; previous staging/VDF/upload logs
and original supplied PNGs are unchanged. Prior 0.30.1 publication evidence is
in ignored dist/workshop-publish/0.30.1-4cd64d25/release-manifest.json. It confirmed
SteamCMD success; public API/page verification was unavailable, not a native PASS.

Prepare an isolated dist/workshop-publish submission from the verified current
archive. Verify CRC, paths, duplicates, case collisions, exact member/source/stage
hashes, Lua-only content, icon alpha/dimensions and unchanged thumbnail. Reuse the
exact prior Workshop preview JPEG (derived from the unchanged PNG under Steam's
1 MB preview limit). Bind final Git SHA, version, IDs, package/VDF/preview/member
hashes and actual validation in a pre-upload manifest. Game source build 25485521;
exact running engine version UNKNOWN. No game/server launch or local installation.

Use the verified existing SteamCMD executable/cached account, App ID 108600 and
existing item 3788592008. VDF contentfolder targets only current Contents/mods/
B47ANCEDSPXTRM. Omit title, visibility and previewfile to preserve their live values. Use current
changenote only. No passwords/tokens in source, VDF, arguments or reports. Inspect
upload behavior: no automatic Steam restart. Verify Committing update...Success
and exit zero; record any public-page/preview verification gap separately.

G7 BLOCKED / NOT TESTED and stable G8 BLOCKED. This is authorized Workshop MP test
distribution only. Humans must verify subscription/download, startup, icon display,
client join/rejoin, synchronization, duplication, persistence and server restarts
before those gates can pass. Ask for separate explicit Steam restart confirmation
after successful upload; a prior decline/approval does not answer that new request.
Keep the exact result in ignored publication provenance; preparation is not upload.
