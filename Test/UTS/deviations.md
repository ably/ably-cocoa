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
