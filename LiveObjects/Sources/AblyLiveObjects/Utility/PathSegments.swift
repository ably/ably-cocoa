import Foundation

/// Dot-delimited path <-> segment list conversions for the path-based public API.
///
/// A dot inside a segment is escaped as `\.` (RTPO4b); parsing honours the escape (RTPO6b). This
/// mirrors ably-java's `PathSegments` (and, transitively, ably-js `pathobject.ts`) exactly, so the
/// stored-path string format agrees byte-for-byte across SDKs.
///
/// Root convention: the root `PathObject` stores the empty string, which represents ZERO segments
/// (RTPO4c) — unlike ably-js, which stores segment arrays and never parses a stored path. Every
/// helper below therefore treats an empty *stored base path* as zero segments via ``parseStored(_:)``;
/// ``parse(_:)`` itself is only ever given user-supplied sub-paths (where `""` means one empty
/// segment, matching ably-js `at("")`) or non-empty stored paths.
///
/// - Note (deviation, mirrored from ably-java): ``join(_:)`` escapes backslashes too (ably-js
///   `_escapePath` escapes only dots). ably-js stores segment ARRAYS and its escaped string is
///   display-only, but here the joined string IS the storage and gets re-parsed by ``parseStored(_:)``
///   on every resolution. Without doubling backslashes, a key ending in `\` would collide with the
///   escaped-dot separator (`["a\", "b"]` -> `a\.b` -> re-parses as `["a.b"]`), breaking lookups and
///   subscriptions. Recorded as a deviation candidate.
@available(macOS 11.0, iOS 14.0, tvOS 14.0, *)
internal enum PathSegments {
    /// RTPO6b — split on unescaped dots; `\.` yields a literal dot; any other `\x` keeps the
    /// backslash; a trailing lone `\` is kept. `""` parses to one empty segment (ably-js parity).
    /// Manual scanner (no regex lookbehind), ported from ably-js `pathobject.ts#at`.
    internal static func parse(_ path: String) -> [String] {
        parse(path, strict: false)
    }

    private static func parse(_ path: String, strict: Bool) -> [String] {
        var segments: [String] = []
        var currentSegment = ""
        var escaping = false
        for char in path {
            if escaping {
                // User-supplied paths keep the escape character unless it escapes a dot, replicating
                // ably-js behaviour where only escaped dots are unescaped; stored paths were produced
                // by `join`, which escapes both '.' and '\', so strict mode unescapes both.
                if char != ".", !(strict && char == "\\") {
                    currentSegment.append("\\")
                }
                currentSegment.append(char)
                escaping = false
                continue
            }
            switch char {
            case "\\":
                escaping = true
            case ".":
                segments.append(currentSegment)
                currentSegment = ""
            default:
                currentSegment.append(char)
            }
        }
        if escaping {
            currentSegment.append("\\")
        }
        segments.append(currentSegment)
        return segments
    }

    /// RTPO4a/RTPO4b — join segments, escaping dots (and backslashes, per the deviation note) inside
    /// segments. Empty list -> `""` (RTPO4c).
    internal static func join(_ segments: [String]) -> String {
        segments
            .map { $0.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: ".", with: "\\.") }
            .joined(separator: ".")
    }

    /// Stored-path parsing: empty stored path = root = zero segments. Use for `this.path`, never raw
    /// ``parse(_:)``. Stored paths only ever come from ``join(_:)``, so this inverts join's full
    /// escaping (`\\` -> `\` as well as `\.` -> `.`).
    internal static func parseStored(_ path: String) -> [String] {
        path.isEmpty ? [] : parse(path, strict: true)
    }

    /// RTPO5c — append one raw key (escaping it) to an existing stored path.
    internal static func appendKey(_ path: String, key: String) -> String {
        join(parseStored(path) + [key])
    }

    /// RTPO6c — append a dot-delimited sub-path to an existing stored path.
    internal static func appendPath(_ path: String, subPath: String) -> String {
        join(parseStored(path) + parse(subPath))
    }
}
