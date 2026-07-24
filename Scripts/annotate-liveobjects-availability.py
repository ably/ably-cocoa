#!/usr/bin/env python3
"""Inserts an @available annotation above every top-level declaration in the
LiveObjects sources that does not already have one.

The ably-cocoa package's declared platform versions are far lower than those
that LiveObjects supports, and SwiftPM has no per-target platform settings, so
availability annotations are how the AblyLiveObjects target declares its true
platform requirements within this package.

The script is idempotent: running it on an already-annotated tree makes no
changes. CI runs it and fails if it produces a diff, which ensures that new
top-level declarations carry the annotation (the compiler independently
enforces this for public declarations via -require-explicit-availability, and
for any declaration that uses newer-than-baseline API).

Usage: Scripts/annotate-liveobjects-availability.py [dir]
(dir defaults to LiveObjects/Sources/AblyLiveObjects, relative to the repo
root, which is assumed to be the working directory)
"""

import re
import sys
from pathlib import Path

ANNOTATION = "@available(macOS 11.0, iOS 14.0, tvOS 14.0, *)"

# A top-level declaration: optional modifiers/attributes on the same line,
# then a declaration-introducing keyword, starting at column 0.
DECL_RE = re.compile(
    r"^(?:(?:public|internal|private|fileprivate|package|open|final|indirect|"
    r"nonisolated(?:\(unsafe\))?|prefix|postfix|infix|"
    r"@\w+(?:\([^)]*\))?)\s+)*"
    r"(?:class|struct|enum|protocol|extension|actor|typealias|func|var|let)\b"
)
# An attribute occupying its own line at column 0 (e.g. @MainActor), which
# belongs to the declaration that follows it.
ATTR_RE = re.compile(r"^@\w+(?:\([^)]*\))?\s*$")


def process(path: Path) -> int:
    lines = path.read_text().splitlines(keepends=True)
    out = []
    insertions = 0
    for line in lines:
        if DECL_RE.match(line):
            # Walk back over any attribute lines already emitted, so the
            # annotation goes above the declaration's whole attribute block.
            attr_start = len(out)
            while attr_start > 0 and ATTR_RE.match(out[attr_start - 1]):
                attr_start -= 1
            block = "".join(out[attr_start:])
            if "@available" not in block:
                out.insert(attr_start, ANNOTATION + "\n")
                insertions += 1
        out.append(line)
    if insertions:
        path.write_text("".join(out))
    return insertions


def main() -> None:
    root = Path(sys.argv[1] if len(sys.argv) > 1 else "LiveObjects/Sources/AblyLiveObjects")
    total = 0
    for path in sorted(root.rglob("*.swift")):
        count = process(path)
        total += count
        if count:
            print(f"{path}: {count}")
    print(f"TOTAL: {total}")


if __name__ == "__main__":
    main()
