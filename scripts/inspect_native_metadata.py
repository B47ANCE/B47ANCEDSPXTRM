#!/usr/bin/env python3
"""Read native class method metadata without executing, extracting or changing game code.

Signatures do not prove Lua dispatch, rendering, synchronization or runtime behavior.
"""
import argparse
import hashlib
import io
import json
from pathlib import Path
import zipfile

TARGETS = {
    "zombie/inventory/InventoryItem.class": {"getWorldZRotation", "setWorldZRotation"},
    "zombie/iso/objects/IsoWorldInventoryObject.class": {"getItem", "syncExtendedPlacement", "transmitCompleteItemToClients"},
    "zombie/iso/sprite/IsoSprite.class": {"renderBloodSplat"},
}


def methods(data):
    stream = io.BytesIO(data)
    def number(size):
        return int.from_bytes(stream.read(size), "big")
    if number(4) != 0xCAFEBABE:
        raise ValueError("Invalid class header")
    stream.read(4)
    count, index, pool = number(2), 1, {}
    widths = {3: 4, 4: 4, 5: 8, 6: 8, 7: 2, 8: 2, 9: 4, 10: 4, 11: 4,
              12: 4, 15: 3, 16: 2, 17: 4, 18: 4, 19: 2, 20: 2}
    while index < count:
        tag = number(1)
        if tag == 1:
            pool[index] = stream.read(number(2)).decode("utf-8", errors="replace")
        else:
            stream.read(widths[tag])
        index += 2 if tag in {5, 6} else 1
    stream.read(6)
    stream.read(number(2) * 2)
    def member():
        flags, name, descriptor = number(2), number(2), number(2)
        for _ in range(number(2)):
            stream.read(2)
            stream.read(number(4))
        return {"name": pool[name], "descriptor": pool[descriptor], "public": bool(flags & 1)}
    for _ in range(number(2)):
        member()
    return [member() for _ in range(number(2))]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--game-root", required=True, type=Path)
    args = parser.parse_args()
    jar = args.game_root / "projectzomboid.jar"
    result = {"evidence": "native metadata only; not Lua/runtime proof",
              "methodScope": "declared methods only; inherited members are omitted", "classes": {}}
    with zipfile.ZipFile(jar) as archive:
        for name, wanted in TARGETS.items():
            data = archive.read(name)
            result["classes"][name] = {"sha256": hashlib.sha256(data).hexdigest(),
                                       "methods": [entry for entry in methods(data) if entry["name"] in wanted]}
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
