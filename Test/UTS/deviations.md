# UTS Deviations (ably-cocoa)

This file records gaps found while running the UTS-derived tests that live in this shared `UTS` test
target — currently the **rest** and **realtime** tiers (`Test/UTS/Tests/rest/**`,
`Test/UTS/Tests/realtime/**`), per `uts/docs/writing-derived-tests.md`. Deviation tests assert the
**spec-correct** behaviour and are gated behind the `RUN_DEVIATIONS` environment variable so normal
runs stay green:

```swift
@Test(.enabled(if: ProcessInfo.processInfo.environment["RUN_DEVIATIONS"] != nil))
```

Reproduce a single deviation with:

```bash
RUN_DEVIATIONS=1 swift test --filter UTS.<TestClass>/<testMethod>
```

> **Objects (`objects/unit`) deviations moved.** The LiveObjects `objects/unit` UTS ports were
> consolidated into the plugin's own test target for java-parity (all 15 specs under
> `LiveObjects/Tests/AblyLiveObjectsTests/UTS/`). Their deviations now live alongside them in
> `LiveObjects/Tests/AblyLiveObjectsTests/UTS/deviations.md`.

## Failing Tests (SDK non-compliance, spec-correct test skipped)

_None currently._

## Adapted Tests (assert actual SDK behaviour, deviation documented)

_None currently._

## Mock Infrastructure Limitations

_None currently._

---

## Entries applied from PR ably/ably-cocoa#2226

The following deviation was authored in PR #2226 (the original objects UTS integration-test PR). It is
a **Failing Tests** entry (SDK non-compliance, spec-correct test skipped) and is appended here rather
than merged into the section above so no existing content is overwritten.

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

---

## PR #2226 application record

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
- **Adapted**: `Test/UTS/deviations.md` entries were appended (not overwritten); `Package.swift`
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
</content>
