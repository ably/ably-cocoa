# UTS Deviations (ably-cocoa)

This file records gaps found while running UTS-derived tests against ably-cocoa, per
`uts/docs/writing-derived-tests.md`. Deviation tests assert the **spec-correct** behaviour and are
gated behind the `RUN_DEVIATIONS` environment variable so normal runs stay green:

```swift
try XCTSkipUnless(ProcessInfo.processInfo.environment["RUN_DEVIATIONS"] != nil)
```

Reproduce a single deviation with:

```bash
RUN_DEVIATIONS=1 swift test --filter UTS.<TestClass>/<testMethod>
```

## Failing Tests (SDK non-compliance, spec-correct test skipped)

_None recorded yet._

## Adapted Tests (assert actual SDK behaviour, deviation documented)

_None recorded yet._

## Mock Infrastructure Limitations

_None recorded yet._
