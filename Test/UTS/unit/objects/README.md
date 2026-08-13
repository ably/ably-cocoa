# UTS objects unit suite

Skill-generated tests for the UTS `objects/unit` specs (`/uts-to-swift`), one Swift Testing suite per
spec, living in the standard UTS location: the `UTS` test target, under `Test/UTS/unit/objects/`.
All 15 `objects/unit` specs are ported here (16 test files — `internal_live_map.md` is split across two
suites — plus `ObjectsUTSHelpers.swift`).

- **Why this location:** the internal-graph specs (`internal_live_counter`, `internal_live_map`,
  `object_id`, `objects_pool`, `parent_references`) reach `internal` members of the plugin. From the
  `UTS` target that access travels via `@testable import AblyLiveObjects` plus the
  `AblyLiveObjectsTesting` extension module (which re-exposes the needed internals through
  `@testable import AblyLiveObjectsTesting`), so the internal graph is reachable and these ports live in
  the UTS-standard tree (rather than needing to sit inside the plugin module).
- **Tag convention:** every port carries a per-test `// UTS: objects/unit/<id>` comment immediately above
  its `@Test`, naming the spec Test ID it covers (consumed by `audit_translation.py`). Each file opens
  with a prose comment naming the source spec (`objects/unit/<spec>.md`). Suite types are named
  `<Name>Tests` (the resolver default). Two of them — `ObjectsPoolTests` and `ParentReferencesTests` —
  share a name with native suites in the `AblyLiveObjectsTests` target; that is fine because they live in
  different targets, and the target-qualified filter form (`UTS.<Name>`) disambiguates them.
- **Running:** `swift test --filter "UTS.<Name>"` from the repo root (e.g.
  `swift test --filter "UTS.InternalLiveMapTests"`), or `swift test --filter UTS` for the whole target.
- **Spec source:** the language-neutral specs live in the [`ably/specification`](https://github.com/ably/specification)
  repo under `uts/objects/unit/`.
- **Deviations** — every place a port diverges from its spec — are recorded in
  [`deviations.md`](deviations.md) (same discipline as `Test/UTS/deviations.md` for the rest/realtime tiers).

## Not in this directory: the native (non-UTS) unit tests

The plugin's own hand-written unit tests live in the plugin test target
(`LiveObjects/Tests/AblyLiveObjectsTests/`) — e.g. `DefaultInstanceTests`, `ParentReferencesTests`,
`PathObjectSubscriptionTests`, `PublicRealtimeObjectTests`, `DefaultPathObjectTests`,
`TestsOnlySeamsTests`, `WireObjectMessageSizeTests`, `InternalDefaultRealtimeObjectsTests`, etc. Only
skill-generated UTS spec ports belong here under `Test/UTS/unit/objects/`.
