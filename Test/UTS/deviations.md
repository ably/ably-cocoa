# UTS Deviations (ably-cocoa)

This file records gaps found while running UTS-derived tests against ably-cocoa, per
`uts/docs/writing-derived-tests.md`, grouped into the manual's four sections (*UTS Spec Errors* /
*Failing Tests* / *Adapted Tests* / *Mock Infrastructure Limitations*). *Failing Tests* keep the
**spec-correct** assertion but are gated behind the `RUN_DEVIATIONS` environment variable so normal
runs stay green; *Adapted Tests* assert the SDK's actual behaviour and run **ungated**:

```swift
@Test(.enabled(if: ProcessInfo.processInfo.environment["RUN_DEVIATIONS"] != nil))
```

Reproduce a single deviation with:

```bash
RUN_DEVIATIONS=1 swift test --filter UTS.<TestClass>/<testMethod>
```

## UTS Spec Errors

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

### RTLM20e7f — outbound binary is raw `Data`, base64 applies at wire serialization

1. **Spec point**: RTLM20e7f (UTS `objects/unit/RTLM20/set-bytes-value-0`)
2. **Spec requirement**: `set()` with a binary value produces `mapSet.value.bytes == "AQID"` (a
   base64-encoded string).
3. **Actual SDK behaviour**: the outbound `ProtocolTypes.ObjectData.bytes` holds raw `Data`; the
   base64 encoding is applied at wire (JSON) serialization, below the `publishAndApply` capture
   point the unit tier asserts at.
4. **Root cause**: `LiveObjects/Sources/AblyLiveObjects/Protocol/ObjectMessage.swift` — OD4
   encoding runs in `toWire(format:)`, after the capture seam.
5. **Test impact**: `UTS.InternalLiveMapApiTests/setWithBytesValue` asserts `Data([1, 2, 3])`
   (which base64-encodes to `AQID`); the spec line is kept as a comment.
6. **Status**: intentional deviation (layering — same wire bytes, asserted pre-encoding).

### RTLC12e1 — non-numeric increment amounts are compile-time-unrepresentable

1. **Spec point**: RTLC12e1 (UTS `objects/unit/RTLC12e1/increment-non-number-0` and
   `objects/unit/RTLC12e1/increment-invalid-amounts-table-0`)
2. **Spec requirement**: `increment()` with a null / non-Number / non-finite amount throws 40003.
3. **Actual SDK behaviour**: `increment(amount:)` takes a `Double`, so the `null` / `"10"` /
   `true` / `[1,2]` / `{n:1}` rows cannot be constructed at all; only the non-finite doubles
   (`NaN` / `Infinity` / `-Infinity`) reach the runtime 40003 check.
4. **Root cause**: typed Swift API surface (`LiveCounterPathObject.increment(amount: Double)`) —
   the invalid inputs are rejected by the compiler, a stronger guarantee than the runtime check.
5. **Test impact**: `UTS.InternalLiveCounterApiTests/incrementWithNonNumberThrows` and
   `incrementInvalidAmountsTable` port the expressible non-finite rows as runtime 40003
   assertions; all spec table rows are kept as comments. Per the spec's own nullish-language
   note, `null` ≡ omitted argument, pinned via the no-argument `increment()` default of 1.
6. **Status**: intentional deviation (type-system guarantee; same class as RTLMV4c below).

### RTLMV4c — `set()` invalid value types are compile-time-unrepresentable

1. **Spec point**: RTLM20e1 / RTLMV4c (UTS `objects/unit/RTLM20/set-invalid-values-table-0`)
2. **Spec requirement**: `set()` with an unsupported value type (`function` / `undefined` /
   `symbol`) throws 40013.
3. **Actual SDK behaviour**: `LiveMapValue` is a closed enum (`.primitive` / `.liveMap` /
   `.liveCounter`); the spec's JavaScript-only constructs have no representation, so the invalid
   call cannot be written.
4. **Root cause**: typed Swift API surface (`LiveMapPathObject.set(key:value: LiveMapValue)`).
5. **Test impact**: `UTS.InternalLiveMapApiTests/setInvalidValuesTableIsCompileTimeUnrepresentable`
   retains the spec pseudocode as comments and passes trivially, documenting the compile-time
   guarantee.
6. **Status**: intentional deviation (type-system guarantee).

## Mock Infrastructure Limitations

*(none)*
