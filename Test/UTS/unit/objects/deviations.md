# Deviations — UTS objects unit suite (`Test/UTS/unit/objects`)

> Records every place a generated `objects/unit` test deviates from its UTS spec. This is the
> ably-cocoa analogue of ably-java's
> `liveobjects/src/test/kotlin/io/ably/lib/liveobjects/uts/deviations.md`: the objects UTS ports live
> in the `UTS` test target (all 15 specs under `Test/UTS/unit/objects/`), so their
> deviations are recorded here alongside them rather than in the shared harness file
> (`Test/UTS/deviations.md`, which covers the rest/realtime tiers).
>
> Structural deviations named below (DEV-\*) are defined in
> `PORT_KOTLIN_TO_SWIFT/05_DEVIATIONS.md`.

Deviation tests that assert the **spec-correct** behaviour (where the SDK is non-compliant) are gated
behind the `RUN_DEVIATIONS` environment variable so normal runs stay green:

```swift
@Test(.enabled(if: ProcessInfo.processInfo.environment["RUN_DEVIATIONS"] != nil))
```

Reproduce a single deviation with:

```bash
RUN_DEVIATIONS=1 swift test --filter '<TestSuite>/<testMethod>'
```

## UTS Spec Errors

_None currently._

## Failing Tests (SDK non-compliance, spec-correct test skipped)

_None currently._

### `objects/unit/realtime_object.md` → RTO27 (channel-state data lifecycle) — RESOLVED

**RTO27a / RTO27b are now implemented in cocoa** (DEV-51). `MutableState.nosync_onChannelStateChanged`
now, in addition to draining the publishAndApply / `get()` sync waiters (RTO20e1 → 92008), clears every
object's data to its zero value without emitting update events on `DETACHED`/`FAILED` (RTO27a1) and
clears the in-progress `SyncObjectsPool` (RTO27a2), while retaining the stored data unchanged on
`SUSPENDED` (RTO27b). The spec-correct assertions (seed the standard pool, drive the state handler,
assert `pool["root"].data == {}` / counter `== 0` / nested map cleared with no update events) require
white-box `ObjectsPool` data introspection that the black-box UTS ports do not expose, so the
coverage lives in the native AblyLiveObjects unit suite instead — `InternalDefaultRealtimeObjectsTests`,
`ChannelStateChangeTests` (DETACHED/FAILED clear, SUSPENDED retention, no-events, SyncObjectsPool clear,
and post-clear re-attach + sync repopulation). There is no dedicated RTO27a/b block in
`objects/unit/realtime_object.md` to enable here.

## Adapted Tests (assert actual SDK behaviour, deviation documented)

### `objects/unit/public_object_message.md` → `PublicObjectMessageTests.swift`

The spec asserts against string action names and a nullable, loosely-typed public shape. ably-cocoa's
public value types (`Path Based API/Public/PublicObjectMessage.swift`) are strongly typed; the ports
assert the cocoa shape. Deviations (defined in `PORT_KOTLIN_TO_SWIFT/05_DEVIATIONS.md`):

- **DEV-5** — Public enums drop `UNKNOWN`. `ObjectOperationAction` has exactly 7 cases (`.mapCreate`,
  `.mapSet`, `.mapRemove`, `.counterCreate`, `.counterInc`, `.objectDelete`, `.mapClear`) and
  `ObjectsMapSemantics` has only `.lww`. The spec's `action == "MAP_SET"` maps to `.mapSet`, etc.
  Unknown wire codes are held internally by `WireEnum.unknown` and never surface publicly. Asserted by
  `DEV5_object_operation_action_seven_distinct_cases`.
- **DEV-6** — `ObjectData` shape. The public `ObjectData` adds a Swift-only `encoding: String?` (no
  wire/Java counterpart), exposes `json` as a raw `String?` (vs Java's parsed `JsonElement`), and uses
  non-optional `Double` for `CounterCreate.count` / `CounterInc.number` (`number` on `ObjectData` is
  `Double?`). Asserted by `objectData_holds_typed_values`, `PAOOP2_counter_inc_only_relevant_field`
  and `PAOOP2_counter_create_with_count`.

**Scope note:** the source spec's cases all drive the wire→public conversion
(`PublicObjectMessage.fromObjectMessage` / `PublicObjectOperation.fromObjectOperation`, i.e. cocoa's
`ProtocolTypes.InboundObjectMessage.toPublicObjectMessage(channelName:)` /
`ProtocolTypes.ObjectOperation.toPublicObjectOperation()`). Both the public-API construction/field
subset (PAOM1/PAOM2/PAOOP1/PAOOP2) and the 13 PAOM3/PAOOP3 conversion cases are ported. The above
deviations (DEV-5/DEV-6) apply equally to the converted public shapes.

### `objects/unit/instance.md` → `InstanceTests.swift`

Cocoa models `Instance` as an **enum** (`.liveMap`/`.liveCounter`/`.primitive`) whose payloads are the
distinct `LiveMapInstance` / `LiveCounterInstance` / `PrimitiveInstance` protocols (AIT-1023), rather
than the spec's base-type + `as*`-cast model (`RTTS9`). Each protocol carries only its applicable
members, so an entire family of the spec's runtime "wrong-type" branches is **compile-time-unrepresentable**
— the tests cannot be written and are recorded here instead of ported:

- **DEV-1** — Instance enum vs `as*` casts. Unrepresentable spec cases: RTINS3b (`Primitive.id() == null`
  — `PrimitiveInstance` has no `id`), RTINS4d (`InternalLiveMap.value() == null` — no `value` on
  `LiveMapInstance`), RTINS5d/RTINS6c/RTINS9c (non-map `get`/`entries`/`size` → null), RTINS12d/RTINS13d
  (`set`/`remove` on non-map → 92007), RTINS14d/RTINS15d (`increment`/`decrement` on non-counter →
  92007), RTINS16c (`subscribe` on primitive → 92007). The spec's `92007` (`ERR_WRONG_INSTANCE_TYPE`)
  code therefore has no cocoa surface at all.
- **DEV-14** — `type` property. `Instance.type` / `PrimitiveInstance.type` (`RTTS8`, non-throwing `ValueType`)
  replace the spec's `as*`-cast discrimination; asserted throughout (e.g. the RTINS ports switch on the
  enum case).
- **Throwing `value`/`size` properties.** `LiveCounterInstance.value`, `PrimitiveInstance.value` and
  `LiveMapInstance.size` are non-optional `get throws(ARTErrorInfo)` (the `throws` is only the RTO25b
  access-precondition check), not the spec's nullable returns.

**Mock-realtime adaptation.** `ObjectsUTSRealtimeObjects` captures `publishAndApply` messages but does
not apply them onto the graph, so the mutation cases (RTINS12/13/14/14a/15/15a) assert the **published
operation** rather than the spec's post-apply value read (`root.get(...).value() == ...`), which needs
the full `InternalDefaultRealtimeObjects` pipeline. Subscribe deliveries (RTINS16/16e2/16f) are driven
by applying an operation to the node directly, the unit stand-in for `mock_ws.send_to_client`.

### `objects/unit/value_types.md` → `ValueTypesTests.swift`

- **DEV-2 / DEV-3** — Primitive collapse. `LiveMap.create` entries and evaluated `MapCreate` values are
  the single `LiveMapValue`/`Primitive` enums (the six spec primitive value-types are collapsed;
  `ValueTypes.swift` deliberate divergence from `RTTS6c`/`RTTS10c`). A bare `"Alice"`/`30` literal lands
  as `.primitive(.string)`/`.primitive(.number)` via the `ExpressibleBy*Literal` conformances.
- **DEV-VT-1** — Evaluation seam. There is no standalone blueprint `evaluate`; cocoa fuses blueprint→
  message generation into `ObjectCreationHelpers` (invoked by `RealtimeObjects.createCounter`/`createMap`).
  The ports bridge via `ObjectsUTS.evaluate(counter:)`/`evaluate(map:)`. Consequently the spec's retained
  local create (`msg.operation.counterCreate` / `mapCreate`, RTLCV4g5 / RTLMV4j5) is exposed as
  `operation.counterCreateWithObjectId.derivedFrom` / `operation.mapCreateWithObjectId.derivedFrom` on
  the outbound message; the top-level `counterCreate`/`mapCreate` fields are left nil for creation ops.
- **Compile-time-unrepresentable validation cases.** Swift's typed blueprint API enforces at compile time
  what the spec validates at runtime, so these have no runtime test: RTLCV3c/RTLCV4a `create("not_a_number")`
  (`initialCount: Double`), RTLMV4a `create(null)` (no null — `create()` vs `create(entries:)`), RTLMV4b
  non-String key (`String` keys), and **RTLMV4c / 40013** invalid value / "graph object as map value"
  (`LiveMapValue` is a closed enum — a function, or a live non-blueprint map, cannot be constructed as
  one). This is **stronger than the spec**, which relies on a runtime 40003/40013 throw.

### `objects/unit/internal_live_counter_api.md` → `InternalLiveCounterApiTests.swift`

- **RTLC12e1 non-finite table.** `increment(amount:)` takes a `Double`, so the `string`/`boolean`/`array`/
  `object`/`null` rows are compile-time-unrepresentable. Only the representable non-finite doubles
  (`NaN`/`Infinity`/`-Infinity`) reach the RTLC12e1 finiteness check (`InternalDefaultLiveCounter.increment`,
  code 40003); those are ported. `null`-means-omitted maps to the no-argument `increment()` default of 1,
  pinned by `InstanceTests.RTINS14a_increment_default`.
- **Mock-realtime adaptation.** As for InstanceTests: the published COUNTER_INC is asserted; the spec's
  post-apply value reads (RTLC12 `value() == 150`, RTLC13 `value() == 85`) need the full pipeline and are
  out of unit scope. Remote updates (RTLC11) are simulated by applying an operation to the node.

### `objects/unit/path_object.md` → `PathObjectTests.swift`

Reads are surfaced through a `DefaultLiveMapPathObject` rooted at the empty path, backed by
`ObjectsUTSSeededRealtimeObjects` wrapping the standard tree seeded directly into an `ObjectsPool`
(`ObjectsUTS.standardPool`) — the unit stand-in for `setup_synced_channel`, which materialises the
same tree via OBJECT_SYNC. Mirrors the native `DefaultPathObjectTests`.

- **DEV-2 (no polymorphic `value()`):** cocoa has no base `PathObject.value()`; a read goes through a
  typed cast — `asPrimitive().value()` (`Primitive?`) or `asLiveCounter().value()` (`Double?`). The
  spec's `po.value()` maps onto those casts; a map or an unresolved path yields `nil` from either
  (the spec's `value() == null`). Applies to RTPO7/RTPO7d/RTPO7e, RTPO3/RTPO3a1/RTPO3c1.
- **`type()` not `getType()`** (RTTS8 discriminator name; consistent with `InstanceTests` DEV-14).
- **RTPO13 / RTPO13c / RTPO13c5 raw `compact()` — no cocoa surface.** Cocoa exposes only
  `compactJson()` (JSON-shaped: bytes as base64, cycles as `{objectId}`). The spec's `compact()`
  returning raw native values (raw bytes, counters as numbers, cycles reused as the same in-memory
  object) has no cocoa method. The JSON-shaped subset is ported as RTPO14 (`compact-json-bytes`,
  including the primitive/counter/nested-map coverage of RTPO13, and `compact-json` cycle-as-objectId
  seeded directly rather than via `mock_ws.send_to_client`).
- **RTPO5b / RTPO6b compile-time-unrepresentable.** `get(key: String)` / `at(path: String)` take
  `String`; a non-string argument (the spec's `get(123)` → 40003) cannot be constructed.

### `objects/unit/path_object_mutations.md` → `PathObjectMutationsTests.swift`

- **DEV-2 (typed casts):** cocoa splits the spec's polymorphic `set/remove/increment/decrement` across
  the typed casts (`asLiveMap()`/`asLiveCounter()`). The RTPO15e/16e/17e/18e "wrong type" branch (→ 92007) is exercised by writing through the _mismatched_ cast (e.g. `asLiveMap()` on a counter).
- **Mock-realtime adaptation.** `ObjectsUTSSeededRealtimeObjects` echoes each captured
  `publishAndApply` operation back onto its existing pool entry (the RTO20 ACK echo), so the spec's
  post-apply value reads (`root.get("name").value() == "Bob"`, `root.get("score").value() == 125`) are
  asserted directly for primitive writes. Only operations that must *create* objects (`*_CREATE`
  blueprints) still need the full `InternalDefaultRealtimeObjects` pipeline and remain out of unit
  scope.

### `objects/unit/internal_live_map_api.md` → `InternalLiveMapApiTests.swift`

Reads run against the seeded standard pool through the path layer (the `RTPO*` accessors delegate to
`RTLM*`); write messages are captured by the seeded double (`captured_messages[0].state[0]` →
`messages[0].operation`).

- **Bytes representation.** RTLM20e7f asserts `mapSet.value.bytes == "AQID"` (base64); cocoa's outbound
  `ObjectData.bytes` holds **raw `Data`** — base64 is applied at wire (JSON) serialization, below this
  layer. The port asserts `Data([1,2,3])`.
- **RTLM20 set-invalid-values-table (40013) compile-time-unrepresentable.** `LiveMapValue` is a closed
  enum, so a function / undefined / symbol value cannot be constructed (as for value_types.md RTLMV4c).
- **Mock-realtime adaptation:** `set-applies-locally` post-apply read is out of scope (only the
  published MAP_SET is asserted).

### `objects/unit/path_object_subscribe.md` → `PathObjectSubscribeTests.swift`

Path dispatch is owned by the engine's apply path, so these drive the **real**
`InternalDefaultRealtimeObjects`: the standard graph is seeded into the engine's pool via
`testsOnly_setPoolEntry` + `testsOnly_setParentReferences` (entries at POOL_SERIAL `"t:0"` so remote
`"t:1"`+ serials win per-entry LWW), and inbound frames are replayed via `testsOnly_applyObjectMessages`
/ `nosync_handleObjectSyncProtocolMessage` (the unit stand-in for `mock_ws.send_to_client`). Mirrors
the native `PathObjectSubscriptionTests`.

- **RTO24b2b — event object = chosen candidate path.** `event.object.path` is the most-preferred
  covered candidate, not the raw change site.
- **RTLO4b4c3c1 — path subs survive tombstone; RTO4b2a — sync-originated events carry `message == nil`.**
  Ported (`event-message-omitted-no-operation` via an OBJECT_SYNC).
- **RTO24b2c throwing-listener unrepresentable.** `PathObjectSubscriptionCallback` is a non-throwing
  `@Sendable` closure, so the spec's "listener throws, error caught" branch cannot be written. The
  observable part (one listener's dispatch does not stop another's) is ported with two listeners.
- **RTPO19g skipped** (subscribe has no side effects on `channel.state`): needs a real channel/
  connection; the unit fixture has only a fixed `CoreSDK` state.

### `objects/unit/live_object_subscribe.md` → `LiveObjectSubscribeTests.swift`

`Instance#subscribe` (RTINS16) delivery is owned by the engine's apply path, so these drive the **real**
`InternalDefaultRealtimeObjects` (as `PathObjectSubscribeTests` does): the standard graph is seeded into
the engine's pool via `testsOnly_setPoolEntry` + `testsOnly_setParentReferences`, instances are obtained
through the production `root.get(key:).instance()` seam, and inbound frames are replayed via
`testsOnly_applyObjectMessages` (the unit stand-in for `mock_ws.send_to_client`). The enriched
`InstanceSubscriptionEvent.message` is the public `ObjectMessage` the engine derives from the inbound
frame (`toPublicObjectMessage`), so `message.serial`/`siteCode`/`operation` are asserted directly.

- **DEV-1 (Instance enum):** the spec's `instance.subscribe(...)` is reached by unwrapping the `Instance`
  enum to its concrete `.liveCounter` / `.liveMap` payload (`LiveCounterInstance` / `LiveMapInstance`),
  which carry `subscribe`. `PrimitiveInstance` has no `subscribe` (RTINS16c is unrepresentable).
- **RTLO4b4c1 noop shape.** The spec models the noop COUNTER_INC as `counterInc: {}` (present but empty).
  cocoa's `WireCounterInc.number` is non-optional, so a number-less increment is represented by an
  **absent** `counterInc` — the same RTLC9h noop branch (helper `ObjectsUTS.counterIncNoopMessage`).
- **RTLO4b6 (no side effects)** is ported in the weakened form observable in the unit fixture: subscribe
  neither throws nor changes the fixed `CoreSDK` channel state (the spec's `channel.state` needs a real
  channel/connection, as for `PathObjectSubscribeTests`' RTPO19g).
- **RTLO4b4c3c** (tombstone deregisters instance subs) is ported and confirmed live; note this is the
  Instance-layer teardown — path subscriptions survive a tombstone (RTLO4b4c3c1, `PathObjectSubscribeTests`).

### `objects/unit/realtime_object.md` → `RealtimeObjectTests.swift`

The engine-drivable subset of the `channel.object` surface is driven through a real
`InternalDefaultRealtimeObjects` proxied by `PublicDefaultRealtimeObject` (with an `ObjectsUTSCoreSDK`
fixing the channel state); sync is completed by feeding the engine an empty OBJECT_SYNC / ATTACHED. This
mirrors the native `PublicRealtimeObjectTests`. Ported: `get()` (RTO23d/RTO23c/RTO23e-failed/RTO4b),
status events + off() (RTO17/RTO18/RTO18d/RTO19 and the SYNCING/SYNCED sequences), the dispose lifecycle,
and the channel-state access/write preconditions (RTO25b/RTO26b, 90001/400).

- **DEV-11 (zero-arg status callback).** `on(event:callback:)` takes a `() -> Void`; the event is known
  from registration, so RTO18e ("listeners called with no arguments") is the shipped shape.
- **RTL33b implicit attach not implementable.** `ChannelConfigGuards.ensureActiveChannel` can only _read_
  channel state through the plugin API (no attach seam), so RTO23's implicit-attach cases (get-implicit-attach,
  RTO23e get-reattaches-detached) are skipped; only the RTL33c FAILED rejection (90001) is exercised.
- **Skipped — mode/echo guards (stubbed, no plugin accessor):** RTO23a, RTO2 mode-enforcement, RTO25a,
  RTO26a (40024) and RTO26c (echoMessages, 40000). See `ChannelConfigGuards`' implementability table.
- **Skipped — out of unit scope:** the publish / apply-on-ACK pipeline (RTO15, all RTO20 variants,
  echo-dedup, ack-\*) and garbage collection (RTO10/RTO10b1/RTO10c1b1, fake timers) need the mock-WS
  OBJECT+ACK path; path-subscription dispatch (RTO24a/RTO24c1) is covered by `PathObjectSubscribeTests`.
- **RTO27** (channel-state data lifecycle) is implemented (DEV-51); its white-box coverage lives in the
  native AblyLiveObjects unit suite (`InternalDefaultRealtimeObjectsTests.ChannelStateChangeTests`) — see the
  "Failing Tests" section above.

## Mock Infrastructure Limitations

The following `objects/unit` cases require the mock-WebSocket harness (`setup_synced_channel` /
`mock_ws.send_to_client` / `install_mock`) and were skipped per the UNIT-only scope — no harness was
built for them:

- **`instance.md`**: RTINS16g (subscription follows identity after a `MAP_SET` repoints `root.score` —
  needs a multi-object graph plus the mock-WS send path) and RTINS16h (subscribe has no side effects on
  channel state — needs a real channel/connection).
- **`value_types.md`**: RTLMV4d1/RTLMV4d2/RTLMV4k (nested depth-first evaluation) — nested blueprint
  entries are materialised by the async `createMap`/`createCounter` pipeline (concrete
  `InternalDefaultRealtimeObjects` + `publishAndApply`), not the pure `ObjectCreationHelpers` seam. Also
  RTLCV4a finiteness (NaN/Infinity → 40003): counter initial-value finiteness is validated in
  `InternalDefaultRealtimeObjects.createCounter` (RTO12f1), above the pure evaluate seam.
- **`internal_live_counter_api.md`**: the `MockWebSocket`-based variants of RTLC12/RTLC13 (`captured_messages`
  via the OBJECT publish path) and RTLC12 `increment-applies-locally` — the published message is asserted
  through the `publishAndApply` mock instead; the local-apply value read is out of unit scope.
- **`internal_live_map_api.md`**: RTLM20e7g (`set` with a `LiveCounter` / `LiveMap`) and RTLM20h1 (nested
  `LiveMap` containing a `LiveCounter`) — setting a blueprint value materialises it via
  `RealtimeObjects.createCounter`/`createMap`, which `DefaultLiveMapInstance` narrows to the concrete
  `InternalDefaultRealtimeObjects` (a `preconditionFailure` otherwise); those publish through the
  mock-WS OBJECT capture path. The seeded double cannot drive them. Primitive value types
  (number/boolean/json/bytes) do not need the pipeline and are ported.

## Untranslated Cases (pending authoring)

Spec cases with **no** ported `@Test` yet and no other deviation record — genuine coverage gaps to be
authored later, distinct from the deliberate scope exclusions above (they are not blocked by missing
infra; they simply have not been written).

### `objects/unit/objects_pool.md` → `ObjectsPoolTests.swift`

- **`objects/unit/RTO5c-RTLM23/sync-clear-timeserial-hides-create-entries-0`** (spec: "Sync with
  clearTimeserial hides initial createOp entries", RTO5c / RTLM23). The case drives
  `pool.processObjectSync(...)` with a root `ObjectState` whose `map.clearTimeserial` is `"05"` and whose
  `createOp.mapCreate` carries entries at serials straddling that clearTimeserial (`old_key` at `"03"`,
  `new_key` at `"07"`), then asserts the pre-clear `old_key` is dropped while `new_key` survives. It is
  translatable within unit scope via direct pool seeding (no mock transport needed, like the other
  `ObjectsPoolTests` sync cases), but has not yet been written. Surfaced by the P2 translation audit as
  `missingInSwift`; recorded here so the gap is tracked pending authoring.
