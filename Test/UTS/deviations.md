# UTS Deviations (ably-cocoa)

This file records gaps found while running UTS-derived tests against ably-cocoa, per
`uts/docs/writing-derived-tests.md`. Deviation tests assert the **spec-correct** behaviour and are
gated behind the `RUN_DEVIATIONS` environment variable so normal runs stay green:

```swift
@Test(.enabled(if: ProcessInfo.processInfo.environment["RUN_DEVIATIONS"] != nil))
```

Reproduce a single deviation with:

```bash
RUN_DEVIATIONS=1 swift test --filter UTS.<TestClass>/<testMethod>
```

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

_None recorded yet._

## Mock Infrastructure Limitations

_None recorded yet._
