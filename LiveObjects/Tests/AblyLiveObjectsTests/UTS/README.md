# UTS objects unit suite

Skill-generated tests for the UTS `objects/unit` specs (`/uts-to-swift`), one Swift Testing suite per
spec, consolidated here in the `AblyLiveObjects` plugin's own test target (`AblyLiveObjectsTests`).

This mirrors ably-java's layout, where all the objects-unit UTS ports live in one place
(`liveobjects/src/test/kotlin/io/ably/lib/liveobjects/uts/unit/`) with `deviations.md` + `README.md`
alongside. All 15 `objects/unit` specs are ported here (16 test files — `internal_live_map.md` is split
across two suites, plus `ObjectsUTSHelpers.swift`).

- **Why this target:** the internal-graph specs (`internal_live_counter`, `internal_live_map`,
  `object_id`, `objects_pool`, `parent_references`) reach `internal` members via
  `@testable import AblyLiveObjects`, which only this target can do; the public-tier specs used to live in
  the standalone `UTS` target (`Test/UTS/`) but were consolidated here so all 15 sit together (java-parity).
- **`@UTS` tag convention:** every file's first line is `// @UTS objects/unit/<spec>.md`, naming the
  source spec it ports. Suite types are named `<Name>UTSTests` to keep this directory uniformly named and
  distinct from the native (non-UTS) suites in the parent directory.
- **Spec source:** the language-neutral specs live in the [`ably/specification`](https://github.com/ably/specification)
  repo under `uts/objects/unit/`.
- **Deviations** — every place a port diverges from its spec — are recorded in
  [`deviations.md`](deviations.md) (same discipline as `Test/UTS/deviations.md` for the rest/realtime tiers).

## Not in this directory: the native (non-UTS) unit tests

The plugin's own hand-written unit tests stay in the parent directory
(`LiveObjects/Tests/AblyLiveObjectsTests/`), **outside** `UTS/` — e.g. `DefaultInstanceTests`,
`ParentReferencesTests`, `PathObjectSubscriptionTests`, `PublicRealtimeObjectTests`,
`DefaultPathObjectTests`, `TestsOnlySeamsTests`, `WireObjectMessageSizeTests`,
`InternalDefaultRealtimeObjectsTests`, etc. These are the analogue of ably-java's non-UTS unit tests,
which it likewise keeps outside `uts/` (in `.../liveobjects/unit/`). Only skill-generated UTS spec ports
belong under `UTS/`.
</content>
