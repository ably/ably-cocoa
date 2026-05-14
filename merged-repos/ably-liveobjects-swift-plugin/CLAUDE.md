# CLAUDE.md

## Build

```sh
swift build
```

## Test

When verifying changes, always run the unit tests first:

```sh
swift run BuildTool test-library --platform macOS --only-unit-tests
```

This is fast (a few seconds) and excludes integration tests. Only run the full test suite if explicitly asked.

## Lint

```sh
swift run BuildTool lint
```

Use `--fix` to auto-fix where possible.

## Specification Document

The _Specification Document_ (or simply "the specification" or "the spec") specifies much of the behaviour of this codebase. It lives in the `specification` repository. If you need to consult it and you haven't been told where to find a local copy, ask.

- The specification is structured as a list of specification points, each with an identifier such as `OD1`. Some specification points have subpoints, e.g. `REC2a`, which in turn can have subpoints like `REC2a1`. In the specification's Markdown source, the start of specification point `OD1` is represented by `` `(OD1)` ``.
- The LiveObjects functionality is referred to in the specification simply as "Objects". The LiveObjects-specific spec points are in a separate file, `specifications/objects-features.md`.
- If you are given a task that requires knowledge of the specification, you must consult it before proceeding. Never guess its contents.
- If the specification is unclear, mention this.

## Swift style

- Satisfy SwiftLint's `explicit_acl` rule (all declarations must specify access control level keywords explicitly).
  - When writing an `extension` of a type, prefer placing the access level on the extension declaration rather than on each individual member.
  - This does not apply to test code.
- When the type being initialised can be inferred, use the implicit `.init(…)` form instead of writing the type name explicitly.
- When the enum type can be inferred, use the implicit `.caseName` form instead of writing the type name explicitly.
- When writing `JSONValue` or `WireValue` types, use the literal syntax enabled by their `ExpressibleBy*Literal` conformances where possible.
- When writing a JSON string, use Swift raw string literals instead of escaping double quotes.
- When importing these modules in library (non-test) code:
  - Ably: `import Ably`
  - `_AblyPluginSupportPrivate`: `internal import _AblyPluginSupportPrivate`
- When writing an array literal that starts with an initialiser expression, start the initialiser on the line after the opening square bracket:

  ```swift
  // Do this:
  objectMessages: [
      InboundObjectMessage(
          id: nil,

  // Not this:
  objectMessages: [InboundObjectMessage(
      id: nil,
  ```
