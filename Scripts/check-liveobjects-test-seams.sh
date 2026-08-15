#!/bin/bash
#
# Guardrail: keeps LiveObjects test-only plumbing out of the shipped sources.
#
# `LiveObjects/Sources/AblyLiveObjects` is meant to host NO `testsOnly_` seams
# except a small, sanctioned set of residuals that physically cannot move into
# the `AblyLiveObjectsTesting` helper target (stored AsyncStream instrumentation
# that production writes, and a protocol requirement a foreign module cannot add).
# This script fails if `Sources/` grows any `testsOnly_` declaration outside that
# allowlist, or if a listed residual disappears (a stale allowlist is also a
# failure). See Test/AblyLiveObjectsTesting/README.md.
#
# Matching is by file path + member name only; line numbers drift and are not
# checked. Dependency-free (bash + grep + comm + sed).

set -euo pipefail

# Resolve the repo root from this script's location so it runs from anywhere.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

SOURCES="LiveObjects/Sources"

# The sanctioned residual seams permitted to remain in Sources/, as "path|member"
# keys. Keep this in sync with the README allowlist. `testsOnly_overridePublish`
# appears twice in CoreSDK.swift (protocol requirement + impl) — one key covers both.
ALLOWLIST="$(cat <<'EOF'
LiveObjects/Sources/AblyLiveObjects/Internal/CoreSDK.swift|testsOnly_overridePublish
LiveObjects/Sources/AblyLiveObjects/Internal/InternalDefaultRealtimeObjects.swift|testsOnly_waitingForSyncEvents
LiveObjects/Sources/AblyLiveObjects/Internal/InternalDefaultRealtimeObjects.swift|testsOnly_receivedObjectProtocolMessages
LiveObjects/Sources/AblyLiveObjects/Internal/InternalDefaultRealtimeObjects.swift|testsOnly_receivedObjectSyncProtocolMessages
LiveObjects/Sources/AblyLiveObjects/Internal/InternalDefaultRealtimeObjects.swift|testsOnly_finishAllTestHelperStreams
EOF
)"

# Collect every testsOnly_ *declaration* site. A declaration has `func`/`var`/`let`
# immediately before the name; comment and doc-list lines (`// testsOnly_…`,
# `/// - testsOnly_…`) never match this pattern, so they are excluded.
FOUND=""
while IFS= read -r line; do
    [ -z "${line}" ] && continue
    file="${line%%:*}"                 # strip "path:" ...
    content="${line#*:}"               # ... leaving "lineno:content"
    content="${content#*:}"            # ... then just "content"
    member="$(printf '%s' "${content}" | grep -oE 'testsOnly_[A-Za-z0-9_]+' | head -1)"
    [ -z "${member}" ] && continue
    FOUND="${FOUND}${file}|${member}"$'\n'
done < <(grep -rnE '(func|var|let)[[:space:]]+testsOnly_' "${SOURCES}" --include='*.swift' || true)

FOUND_SORTED="$(printf '%s' "${FOUND}" | grep -v '^$' | sort -u || true)"
ALLOW_SORTED="$(printf '%s\n' "${ALLOWLIST}" | grep -v '^$' | sort -u)"

status=0

# Direction 1: declaration sites that are NOT on the allowlist -> new pollution.
UNEXPECTED="$(comm -23 <(printf '%s\n' "${FOUND_SORTED}") <(printf '%s\n' "${ALLOW_SORTED}") || true)"
if [ -n "${UNEXPECTED}" ]; then
    status=1
    echo "ERROR: unexpected testsOnly_ declaration(s) found in ${SOURCES} that are not on the residual allowlist:" >&2
    while IFS= read -r entry; do
        [ -z "${entry}" ] && continue
        echo "  - ${entry%%|*}: ${entry##*|}" >&2
    done <<< "${UNEXPECTED}"
    echo "  Move each to the AblyLiveObjectsTesting helper target, or (if truly immovable) add it to the allowlist" >&2
    echo "  in this script AND Test/AblyLiveObjectsTesting/README.md." >&2
fi

# Direction 2: allowlist entries that no longer exist -> stale allowlist.
MISSING="$(comm -13 <(printf '%s\n' "${FOUND_SORTED}") <(printf '%s\n' "${ALLOW_SORTED}") || true)"
if [ -n "${MISSING}" ]; then
    status=1
    echo "ERROR: allowlisted testsOnly_ residual(s) no longer present in ${SOURCES} (stale allowlist):" >&2
    while IFS= read -r entry; do
        [ -z "${entry}" ] && continue
        echo "  - ${entry%%|*}: ${entry##*|}" >&2
    done <<< "${MISSING}"
    echo "  Remove the entry from this script AND Test/AblyLiveObjectsTesting/README.md." >&2
fi

if [ "${status}" -ne 0 ]; then
    exit "${status}"
fi

echo "OK: ${SOURCES} contains only the $(printf '%s\n' "${ALLOW_SORTED}" | grep -c '^') sanctioned testsOnly_ residual(s)."
