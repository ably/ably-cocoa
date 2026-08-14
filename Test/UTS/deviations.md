# UTS Deviations (ably-cocoa)

This file records gaps found while running the UTS-derived tests that live in this shared `UTS` test
target — all tiers and modules, including the LiveObjects `objects` ports (`Test/UTS/unit/**`,
`Test/UTS/integration/**`), per `uts/docs/writing-derived-tests.md`. Deviation tests assert the
**spec-correct** behaviour and are gated behind the `RUN_DEVIATIONS` environment variable so normal
runs stay green:

```swift
@Test(.enabled(if: ProcessInfo.processInfo.environment["RUN_DEVIATIONS"] != nil))
```

Reproduce a single deviation with:

```bash
RUN_DEVIATIONS=1 swift test --filter UTS.<TestClass>/<testMethod>
```

> **Objects (`objects/unit`) deviations live here.** The LiveObjects `objects/unit` UTS ports live in
> this shared target at `Test/UTS/unit/objects/` (the earlier java-parity consolidation under
> `LiveObjects/Tests/AblyLiveObjectsTests/UTS/` was undone by the tests restructure), and their
> deviations are recorded in this shared file — there is no module-scoped `deviations.md`.

**Sectioning rule.** Entries are grouped into the four canonical sections below — **UTS Spec Errors**,
**Failing Tests**, **Adapted Tests**, **Mock Infrastructure Limitations** — kept in that order per
`uts/docs/writing-derived-tests.md` § *Recording deviations*. A new entry is inserted into its
respective section, never appended at the end of the file; empty sections are kept and marked
`*(none)*` so a reader can tell an empty category from a forgotten one.

## Shape-deviation vocabulary (objects unit tier)

Internal-API **shape** differences (unit tier only, per the manual's "Internal-API shape differs"
category) are named once here and cited by tag from each affected **Adapted Tests** entry below:

- **(S-1) `*CreateWithObjectId` construction shape.** The spec constructs `mapCreateWithObjectId`
  with `objectId` / `semantics` / `entries` fields (and `counterCreateWithObjectId` with
  `objectId` / `count`) alongside `derivedFrom`. cocoa's internal
  `ProtocolTypes.MapCreateWithObjectId` / `CounterCreateWithObjectId` instead carry
  `initialValue` / `nonce` / `derivedFrom` (the MCRO2/CCRO2 wire shape) — the duplicated create
  fields do not exist; the retained source create lives wholly in `derivedFrom`
  (RTLMV4j5 / RTLCV4g5).

## UTS Spec Errors (UTS spec contradicts the features spec or is internally inconsistent)

*(none)*

## Failing Tests (SDK non-compliance, spec-correct test skipped)

### RSL1l1 — no publish-with-params API

1. **Spec point**: RSL1l1 (UTS `rest/integration/RSL1l1/publish-params-force-nack-0`)
2. **Spec requirement**: Additional publish params can be supplied with a publish and are
   transmitted to the server as request query params (the UTS test exercises this with the
   `_forceNack: "true"` test param, expecting the publish to fail with error code 40099).
3. **Actual SDK behaviour**: ably-cocoa exposes no publish overload accepting request params.
   `params:` exists only on the message-edit methods (`updateMessage:operation:params:callback:`,
   `deleteMessage:…`, `appendMessage:…` — RSL15f), on both `ARTChannelProtocol` and the internal
   `ARTChannel`, so the spec's `channel.publish(message:, params:)` cannot be expressed at all.
4. **Root cause**: `Source/include/Ably/ARTChannelProtocol.h` / `Source/ARTRestChannel.m` — the
   publish family (`publish:data:…`, `publish:` messages array) has no `params:` variant; RSL1l1 is
   unimplemented.
5. **Test impact**: `UTS.PublishTests/test_RSL1l1_publish_params_with_forceNack` — the spec-correct
   test cannot compile, so the method carries the spec pseudocode as comments, is gated behind
   `RUN_DEVIATIONS`, and fails via `Issue.record` pointing here when enabled. Reproduce:
   `RUN_DEVIATIONS=1 swift test --filter UTS.PublishTests/test_RSL1l1_publish_params_with_forceNack`.

## Adapted Tests (assert actual SDK behaviour, deviation documented)

### PAOOP3b2 / PAOOP3c2 — `*CreateWithObjectId` source construction (S-1)

1. **Spec point**: PAOOP3b2, PAOOP3c2 (UTS `objects/unit/PAOOP3/map-create-from-with-object-id-0`,
   `objects/unit/PAOOP3/counter-create-from-with-object-id-0`).
2. **Spec requirement**: build the source operation's `mapCreateWithObjectId` /
   `counterCreateWithObjectId` with `objectId` / `semantics` / `entries` (resp. `count`) plus
   `derivedFrom`, then resolve the public `mapCreate` / `counterCreate` from the derived create.
3. **Actual SDK behaviour**: the internal `WithObjectId` types carry only
   `initialValue` / `nonce` / `derivedFrom` (S-1); the PAOOP3b2/PAOOP3c2 resolution reads only
   `derivedFrom`.
4. **Root cause**: internal wire-type modelling choice
   (`LiveObjects/Sources/AblyLiveObjects/Protocol/ObjectMessage.swift`,
   `ProtocolTypes.MapCreateWithObjectId` / `CounterCreateWithObjectId`); not observable through the
   public API.
5. **Test impact**: this deviation was carried by the `UTS.PublicObjectMessageTests` suite
   (`Test/UTS/unit/objects/PublicObjectMessageTests.swift`), which constructed the source via
   `initialValue` / `nonce` / `derivedFrom` while keeping every spec assertion unchanged (coverage
   preserved — only the construction shape was adapted, so the cases ran ungated). That suite has
   since been removed; this entry is retained so the S-1 shape adaptation is recorded and re-applied
   when the `public_object_message.md` spec is re-translated and the suite is regenerated.
6. **Status**: intentional (internal-API shape difference, unit tier only; no SDK fix expected).

## Mock Infrastructure Limitations

*(none)*

---

## Appendix: PR #2226 application record

*(Changelog, not a deviation entry.)* The RSL1l1 entry above was authored in PR
ably/ably-cocoa#2226 (the original objects UTS integration-test PR); it is a **Failing Tests** entry
and has been placed in that section rather than appended at the file end.

Applied on branch `feature/liveobjects-implementation` against the completed LiveObjects
implementation (the PR was originally authored when the public API was a trapping skeleton).

- **Applied (integration tier)**: `Test/UTS/integration/standard/objects/{ObjectsGcTests,ObjectsLifecycleTests,ObjectsSyncTests}.swift`
  + `helpers/{ObjectsIntegrationHelpers,ObjectsRestProvisioning}.swift`; the proxy-tier
  `Test/UTS/integration/proxy/objects/ObjectsFaultsTests.swift`; and the rest-tier
  `Test/UTS/integration/standard/rest/{HistoryTests,PresenceTests,PublishTests}.swift`. These are the
  point of this PR: the objects integration tests are now driveable against the finished
  implementation.
- **Applied (skill/reference)**: `.claude/skills/uts-to-swift/SKILL.md` (integration/proxy tier notes)
  and `.claude/skills/uts-to-swift/references/objects-mapping.md` (objects UTS translation notes).
- **Applied (Package.swift)**: added the `AblyLiveObjects` dependency to the `UTS` test target so the
  objects integration tests can import the plugin.
- **Skipped**: no unit-tier objects tests were in this PR (the 15 objects unit specs were already
  consolidated into `LiveObjects/Tests/AblyLiveObjectsTests/UTS/`), so there were no duplicates to
  drop.
- **Adapted**: `Test/UTS/deviations.md` entries were preserved (not overwritten); `Package.swift`
  reconciled by hand due to a trailing-comma context drift.
- **Enabled**: the `.disabled("The path-based LiveObjects public API is not yet implemented…")`
  trait was removed from all four objects suites — the implementation has landed, which is the
  condition the trait's own text set for its removal.
- **No test adaptations were needed**: the suites run exactly as authored in the PR. Two
  implementation-side gaps they surfaced were fixed in the SDK instead (stakeholder-approved):
  the RTL33b implicit attach in `RealtimeObject.get()` (formerly DEV-46; new plugin-API accessor)
  and a `deinit`-on-internal-queue teardown crash in the objects engine. A `siteCode` seeding hole
  (RTO20 local echo silently skipped for channels created after CONNECTED) was also found via these
  tests' logs and fixed.
- **Results at time of application** (macOS, nonprod sandbox): standard objects suites 12/12 passed;
  proxy `ObjectsFaultsTests` 5/5 passed; rest-tier History/Presence/Publish 27/27 passed with
  `test_RSL1l1_publish_params_with_forceNack` skipped per the RSL1l1 deviation entry above.
