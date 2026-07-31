# `objects` UTS → ably-cocoa `AblyLiveObjects`: ably-js ⇄ Swift type/interface map

Read this **before translating any spec from the `objects` module** (target module
`AblyLiveObjects`, in `LiveObjects/Sources/AblyLiveObjects`). The `objects` UTS specs are written
in a language-agnostic pseudocode that mirrors the **ably-js** LiveObjects API — a
dynamically-typed surface with a single polymorphic `PathObject` / `Instance`, `Promise`-returning
mutators, and raw JS values. ably-cocoa is a **statically-typed SDK** and implements the *Typed-SDK
variant* of the spec (`RTTS1`–`RTTS10` in `objects-features.md`) — with two deliberate,
Swift-idiomatic consolidations recorded on AIT-1023 and in the API's doc comments:

1. the spec's six primitive path-object / instance sub-types collapse into a single
   `PrimitivePathObject` / `PrimitiveInstance` resolving to a pattern-matchable `Primitive` enum
   (divergence from `RTTS6c`/`RTTS10c`), and
2. `Instance` is an **enum** (`.liveMap` / `.liveCounter` / `.primitive`), not a base type with
   throwing `as*` casts (`RTTS9`), so discrimination is compile-time-exhaustive.

So almost every spec line needs a mechanical rewrite, not a literal transcription. This doc is that
rewrite table. The canonical bridge is the spec's own Interface Definition
(`## Interface Definition {#idl}`) and its `=== Typed-SDK variant (RTTS1-RTTS10) ===` block; where
this doc and the IDL disagree, check the Swift source (`Path Based API/Public/*.swift`) — it is the
ground truth for this SDK, including the two consolidations above.

> ⚠️ **Runtime status.** The path-based public API is currently a
> **skeleton**: every `Default*` implementation traps via `notImplemented()` (`fatalError`). Until
> the implementation lands, `objects` specs are **translate-only** — generate + compile (Step 5)
> but do NOT run (Step 6); an evaluation run doesn't fail, it *crashes the test process*. For the
> same reason, every generated public-API suite must carry a
> `.disabled("The path-based LiveObjects public API is not yet implemented …")` trait alongside
> `.serialized` — otherwise a routine `swift test --filter UTS` run (the documented workflow for
> the whole target) fatal-errors. Remove the traits when the implementation lands. Re-check this
> note (grep the SDK for `notImplemented()`) before choosing translate-and-evaluate.

## Table of contents

1. [The three layers (don't conflate them)](#1-the-three-layers)
2. [Entry point & channel access](#2-entry-point)
3. [Async: Promise/await → Swift `try await` (typed throws)](#3-async)
4. [Dynamic `PathObject` → typed `PathObject` views](#4-pathobject)
5. [Dynamic `Instance` → the `Instance` enum](#5-instance)
6. [Creation value types & the `LiveMapValue` union](#6-value-types)
7. [Mutations (set / remove / increment / decrement)](#7-mutations)
8. [Subscriptions, listeners & events](#8-subscriptions)
9. [Sync-state events (`object.on('synced')`)](#9-sync-state)
10. [`ValueType` & type discrimination](#10-valuetype)
11. [Message / operation types (`PublicAPI::ObjectMessage` →)](#11-messages)
12. [Errors & error codes](#12-errors)
13. [Internal-graph types (unit specs) — important caveats](#13-internal-graph)
14. [Integration-test helpers — REST fixture provisioning](#14-integration-helpers)
15. [Worked example](#15-worked-example)
16. [Quick symbol index](#16-symbol-index)

---

## 1. The three layers <a id="1-the-three-layers"></a>

The single biggest source of confusion: the spec uses the names `LiveMap` / `LiveCounter` for **two
different things**, and a third *internal* layer underneath. Keep them straight:

| Layer | Spec name | ably-js | ably-cocoa | Where |
|---|---|---|---|---|
| **Creation value type** — immutable blueprint you pass *into* `set` | `LiveMap` / `LiveCounter` (the `RTLMV*` / `RTLCV*` classes) | `LiveMap.create()` / `LiveCounter.create()` | `struct LiveMap` / `struct LiveCounter` | `Path Based API/Public/ValueTypes.swift` |
| **Public read/write view** — what you navigate & subscribe on | `PathObject`, `Instance` | `PathObject`, `Instance` | `PathObject` protocol + typed views (§4); `Instance` enum (§5) | `Path Based API/Public/PathObject.swift` / `Instance.swift` |
| **Internal graph object** — the live CRDT node | `InternalLiveMap` / `InternalLiveCounter` (`RTLM*` / `RTLC*`), `ObjectsPool` | internal | `InternalDefaultLiveMap` / `InternalDefaultLiveCounter` / `ObjectsPool` — `internal`, not visible to importers | `Internal/` — see §13 |

So when a spec says `counter = LiveCounter.create(5)` and passes it to `set`, that's the **value
type** (`LiveCounter.create(initialCount: 5)`). When a spec says "the resolved value is an
`InternalLiveCounter` with `.data == 5`", that's the **internal graph node** (§13). When a spec
navigates `root.get("counter").value()`, that's the **public view** (`PathObject`).

---

## 2. Entry point & channel access <a id="2-entry-point"></a>

| Spec / ably-js | ably-cocoa (Swift) |
|---|---|
| `channel.object` (objects entry point) | `channel.object` — a **property** on `ARTRealtimeChannel` of type `any RealtimeObject` (`RTL27`). |
| `root = AWAIT channel.object.get()` | `let root = try await channel.object.get()` — `async throws(ARTErrorInfo)`, returns `any LiveMapPathObject` (always a map view, per `RTTS6d`/`RTO23f`). |
| `channel.object.get<MyType>()` (ably-js generic) | **No generic.** The root is always `any LiveMapPathObject`; narrow downstream with the `as*` views (§4). Drop the type parameter entirely. |
| Channel needs object modes | `let options = ARTRealtimeChannelOptions(); options.modes = [.objectPublish, .objectSubscribe]; let channel = realtime.channels.get(name, options: options)` |

Accessing `channel.object` without the `LiveObjects` plugin in `ARTClientOptions.plugins` is a
programmer error (traps). The exact wiring is
`options.plugins = [.liveObjects: AblyLiveObjects.Plugin.self]` plus `import AblyLiveObjects` — on
the integration tier it is packaged as `objectsClientOptions(key:useBinaryProtocol:)` in
`Test/UTS/integration/standard/objects/helpers/ObjectsIntegrationHelpers.swift`; **use that
builder, don't hand-wire the plugin per test**.

---

## 3. Async: Promise / await → Swift `try await` (typed throws) <a id="3-async"></a>

Every spec `AWAIT`/Promise-returning call is a Swift `async throws(ARTErrorInfo)` method — no
future type to unwrap, and the thrown error is **already** an `ARTErrorInfo` (typed throws):

| Spec / ably-js | ably-cocoa |
|---|---|
| `AWAIT channel.object.get()` | `try await channel.object.get()` → `any LiveMapPathObject` |
| `AWAIT pathObj.set(k, v)` / `.remove(k)` | `try await mapView.set(key: k, value: v)` / `.remove(key: k)` → `Void` |
| `AWAIT counterObj.increment(n)` / `.decrement(n)` | `try await counterView.increment(amount: n)` / `.decrement(amount: n)` → `Void` |
| `AWAIT instance.set(...)` etc. | `try await` on the matching `LiveMapInstance` / `LiveCounterInstance` method |

Subscriptions are **not** async — `subscribe(...)` returns synchronously (but `throws`, §8).
Path-resolving reads (`exists()`, `type()`, `value()`, `entries()`, …) are synchronous throwing
**methods** — the `try` is for the `RTO25` access-precondition check, not for I/O.

**Deferred awaits (`x_future = op()` … `AWAIT x_future`).** `realtime_object.md` repeatedly starts
an operation, does something else (e.g. delivers a mock message), *then* awaits — including
`AWAIT inc_future FAILS WITH error`. Swift has no bare future: wrap the operation in a `Task` at
the "start" line and await its `value` at the `AWAIT` line. `Task`'s error type is untyped, so
re-narrow to `ARTErrorInfo` when asserting a failure:

```text
# spec
get_future = channel.object.get()
mock_ws.send_to_client(...)            # unblocks the get
root = AWAIT get_future
```
```swift
let getTask = Task { try await channel.object.get() }
mockWs.sendToClient(...)
let root = try await getTask.value
// failure form: AWAIT inc_future FAILS WITH error (code N)
do {
    _ = try await incTask.value
    Issue.record("expected the deferred operation to fail")
} catch {
    #expect(try #require(error as? ARTErrorInfo).code == N)   // Task erases the typed throw
}
```

---

## 4. Dynamic `PathObject` → typed `PathObject` views <a id="4-pathobject"></a>

In the spec/ably-js a `PathObject` is polymorphic: `get`, `at`, `value`, `set`, `increment`,
`entries`… all hang off the one object. In ably-cocoa the base `PathObject` protocol exposes
**only** the type-agnostic members; everything type-specific lives on a view protocol you reach via
an `as*` refinement. There are exactly **three** views (not the eight the spec's typed variant
sketches): map, counter, and one consolidated primitive view.

**Base `PathObject`** — always available:

| Spec / ably-js | ably-cocoa |
|---|---|
| `pathObj.path()` | `pathObj.path` — a **property** (`String`; the root's is `""`) |
| `pathObj.instance()` | `try pathObj.instance()` → `Instance?` (nil when resolution fails or the value is a primitive — note this is narrower than ably-js/`RTPO8f`; check the Swift doc comment when a spec wraps a primitive) |
| `pathObj.compactJson()` | `try pathObj.compactJson()` → `JSONValue?` |
| `pathObj.compact()` | **Not implemented in ably-cocoa** (`RTTS3f`: typed SDKs need not implement `compact`). Use `compactJson()`; if a spec genuinely needs the non-JSON `compact()` shape, that's a deviation — flag it. |
| `pathObj.subscribe(listener[, opts])` | `try pathObj.subscribe(options:listener:)` → `any Subscription` (§8) |
| *(typed-SDK addition)* exists check | `try pathObj.exists()` → `Bool` (`RTTS4a`) |
| `pathObj.getType()` | `try pathObj.type()` → `ValueType?` — nil when nothing resolves (§10) |
| — view refinements — | `asLiveMap()`, `asLiveCounter()`, `asPrimitive()` — pure type refinements, **never throw**, don't resolve the path (`RTTS5`) |

**View casts never throw** (`RTTS5d`) — they only re-wrap. A wrong cast surfaces later: read ops on
the wrong-typed view return `nil`/empty; write ops throw (§12). So
`try root.get(key: "k").asLiveCounter().value()` returns `nil` if `k` isn't a counter, rather than
throwing.

**Map-only members** — require `asLiveMap()` → `any LiveMapPathObject`:

| Spec / ably-js (on a `PathObject`) | ably-cocoa |
|---|---|
| `pathObj.get(key)` | `mapView.get(key: key)` → `any PathObject` (non-resolving navigation) |
| `pathObj.at("a.b.c")` | `mapView.at(path: "a.b.c")` → `any PathObject` (non-resolving) |
| `pathObj.entries()` | `try mapView.entries()` → `[(key: String, value: any PathObject)]` |
| `pathObj.keys()` / `.values()` | `try mapView.keys()` → `[String]` / `try mapView.values()` → `[any PathObject]` |
| `pathObj.size()` | `try mapView.size()` → `Int?` (nil off-map) |
| `pathObj.set(key, value)` | `try await mapView.set(key: key, value: <LiveMapValue>)` (§6, §7) |
| `pathObj.remove(key)` | `try await mapView.remove(key: key)` |

> The **root** is already an `any LiveMapPathObject` (from `channel.object.get()`), so
> `root.get(key:)` / `root.set(key:value:)` need no cast — only deeper, freshly-navigated
> `PathObject`s do.

**Iterating & membership.** `entries()` returns an array of labelled tuples; `keys()` / `values()`
return arrays. The spec's tuple-destructuring loops and `IN` membership map directly:

```text
# spec
FOR [key, pathObj] IN root.entries(): …
ASSERT "name" IN root.keys()
keys = list(root.keys())
```
```swift
for (key, pathObj) in try root.entries() { … }
#expect(try root.keys().contains("name"))
let keys = try root.keys()                      // already an Array — no materialisation step
```

These live on `LiveMapPathObject`, so a *navigated* node needs `asLiveMap()` first
(`try root.get(key: "score").asLiveMap().entries()`); `root` itself doesn't.

**Counter-only members** — require `asLiveCounter()` → `any LiveCounterPathObject`:

| Spec / ably-js | ably-cocoa |
|---|---|
| `pathObj.value()` *(when it's a counter)* | `try counterView.value()` → `Double?` (counter value, else nil) |
| `pathObj.increment([n])` | `try await counterView.increment()` / `.increment(amount: n)` |
| `pathObj.decrement([n])` | `try await counterView.decrement()` / `.decrement(amount: n)` |

**Primitive value reads — the consolidation to know.** The spec's typed-SDK variant defines
six primitive sub-types (`NumberPathObject`, `StringPathObject`, …); ably-cocoa **collapses them
into one** `PrimitivePathObject` whose `value()` returns a `Primitive?` enum you pattern-match or
read via convenience getters (documented divergence from `RTTS6c`; the six-way split appears
nowhere in this SDK):

| Spec resolves to | ably-cocoa |
|---|---|
| number | `try node.asPrimitive().value()?.numberValue` → `Double?` |
| string | `try node.asPrimitive().value()?.stringValue` → `String?` |
| boolean | `try node.asPrimitive().value()?.boolValue` → `Bool?` |
| binary | `try node.asPrimitive().value()?.dataValue` → `Data?` |
| JSON object | `try node.asPrimitive().value()?.jsonObjectValue` → `[String: JSONValue]?` |
| JSON array | `try node.asPrimitive().value()?.jsonArrayValue` → `[JSONValue]?` |

So a spec's `pathObj.asNumber().value()` becomes `pathObj.asPrimitive().value()?.numberValue`, and
a spec's `pathObj.asString()` *cast on its own* has no Swift counterpart — fold it into the
`asPrimitive()` read. The getters are stricter the same way the spec's typed accessors are: each
returns `nil` unless the primitive is exactly that case.

> **Counter vs number.** The dynamic `PathObject#value` (`RTPO7`) returns "the resolved counter
> value *or* any primitive". Translate "ASSERT pathObj.value() == 5" against a **counter** as
> `#expect(try root.get(key: "c").asLiveCounter().value() == 5)`, not via `asPrimitive()`.
>
> **Numbers are just `Double`.** Counter `value()` is `Double?`, `Primitive.number` carries
> `Double`, and `size()` is `Int?` — Swift literals convert, so `== 110` and `size() == 7` work
> as written, no numeric-suffix normalisation needed. A spec `size() == null` (called on a
> non-map) is `#expect(try node.asLiveMap().size() == nil)` — the cast doesn't throw and `size()`
> returns nil off-map.
>
> **Dynamic `value()` reads in `poll_until` conditions (integration tier).** `pollUntil` closures
> are non-throwing, so the typed reads above get wrapped in `try?` — and SE-0230 **flattens** the
> nested optional (`try? node.asPrimitive().value()` yields `Primitive?`, not `Primitive??`; a
> further `?.` chain on the `guard let`-unwrapped value is a compile error). Don't inline the
> `try?`: use the packaged non-throwing readers in
> `Test/UTS/integration/standard/objects/helpers/ObjectsIntegrationHelpers.swift` —
> `counterValue(at:)` / `stringValue(at:)` / `numberValue(at:)`. They return `nil` when the path
> doesn't resolve or resolves to a different type, which is also how the spec's `value() == null`
> (the tombstoned/absent case, `RTLM5d2h`) is asserted. A thrown `RTO25` precondition error also
> reads as `nil` there — fine on the integration tier, which only reads on ATTACHED channels.

**Path strings & dot-escaping (`RTPO4`/`RTPO4b`/`RTPO6`).** `path` is a dot-delimited `String`
property; the root's is `""`. A literal dot *inside* a segment is escaped as `\.`, and `at(path:)`
parses `\.` back — so `path` round-trips. Mind Swift's own backslash escaping (`"a\\.b.c"` is the
string `a\.b.c`):

```text
# spec                                     # ably-cocoa (Swift)
ASSERT root.path() == ""                    #expect(root.path == "")
ASSERT root.get("a").get("b").path()        #expect(root.get(key: "a").asLiveMap().get(key: "b").path == "a.b")
       == "a.b"
po = root.at("a\.b.c")                      let po = root.at(path: "a\\.b.c")     // segments ["a.b", "c"]
ASSERT po.path() == "a\.b.c"                #expect(po.path == "a\\.b.c")
```

---

## 5. Dynamic `Instance` → the `Instance` enum <a id="5-instance"></a>

**Structural divergence from ably-js and from the spec's typed variant:** `Instance` is a Swift
**enum** with three
cases carrying the typed payload — there are no `as*` casts and no throwing-cast mismatch path
(`RTTS9d` is unrepresentable by construction). Discriminate by `switch` / `guard case`:

```swift
let instance = try #require(try root.get(key: "game").instance())
guard case let .liveMap(map) = instance else { Issue.record("expected a map instance"); return }
```

> **`Instance` has no convenience getters.** Unlike `LiveMapValue` (which offers `liveCounterValue`
> etc.), the `Instance` enum exposes only its cases — extracting a payload (e.g. for a spec's
> `pathObj.instance().id`) always needs the `guard case` above. For the recurring counter-id read
> the integration tier packages it as `counterInstanceId(at:)` in
> `Test/UTS/integration/standard/objects/helpers/ObjectsIntegrationHelpers.swift` (uses
> `try #require` + `guard case`, stopping the test on a mismatch).

**On the enum itself** (`Instance`):

| Spec / ably-js | ably-cocoa |
|---|---|
| `instance.getType()` | `instance.type` — non-optional `ValueType` (`RTTS8`), O(1) property |
| `instance.compactJson()` | `try instance.compactJson()` → `JSONValue` (**non-optional**, `RTINS11c`) |
| `instance.compact()` | **Not implemented** (`RTTS7d`, same as `PathObject`). Use `compactJson()`; flag a deviation if a spec needs `compact()`. |
| `instance.asLiveMap()` / `.asLiveCounter()` / throwing casts | **No casts.** `switch instance { case let .liveMap(map): … }` — a spec case asserting "cast on wrong type throws" is not expressible (the mismatch is a compile-time impossibility); note it as a deviation, don't force it. |

**`LiveMapInstance`** (payload of `.liveMap`):

| Spec / ably-js | ably-cocoa |
|---|---|
| `instance.id` | `map.id` → `String` (non-optional, `RTINS3`) |
| `instance.get(key)` | `try map.get(key: key)` → `Instance?` |
| `instance.entries()` / `.keys()` / `.values()` | `try map.entries()` → `[(key: String, value: Instance)]` / `try map.keys()` → `[String]` / `try map.values()` → `[Instance]` |
| `instance.size()` | `try map.size` → `Int` (**throwing property**, non-optional — the instance is already resolved; `throws` only for the `RTO25` precondition) |
| `instance.set(key, value)` / `.remove(key)` | `try await map.set(key:value:)` / `.remove(key:)` |
| `instance.subscribe(listener)` | `try map.subscribe(listener:)` → `any Subscription` |
| `instance.compactJson()` | `try map.compactJson()` → `JSONValue` |

**`LiveCounterInstance`** (payload of `.liveCounter`):

| Spec / ably-js | ably-cocoa |
|---|---|
| `instance.id` | `counter.id` → `String` |
| `instance.value()` | `try counter.value` → `Double` (**throwing property**, non-optional, `RTTS10b`) |
| `instance.increment([n])` / `.decrement([n])` | `try await counter.increment()` / `.increment(amount: n)` / `.decrement()` / `.decrement(amount: n)` |
| `instance.subscribe(listener)` | `try counter.subscribe(listener:)` → `any Subscription` |

**`PrimitiveInstance`** (payload of `.primitive`) is **read-only** — `try prim.value` → `Primitive`
(non-optional throwing property), `prim.type` (the *specific* primitive `ValueType`, e.g.
`.string`), `try prim.compactJson()`. No `id`, no `get`/`set`, no `subscribe` — one consolidated
type instead of the spec's six (`RTTS10c` divergence, same rationale as §4).

---

## 6. Creation value types & the `LiveMapValue` union <a id="6-value-types"></a>

ably-cocoa can't accept "any JS value" into `set`, so writes take the `LiveMapValue` enum
(`.primitive(Primitive)` / `.liveMap(LiveMap)` / `.liveCounter(LiveCounter)`) — but **literals need
no wrapper at all**: `LiveMapValue` conforms to
`ExpressibleBy{String,Integer,Float,Boolean,Array,Dictionary}Literal`.

| Spec / ably-js | ably-cocoa |
|---|---|
| `LiveCounter.create()` | `LiveCounter.create()` (initial count 0) |
| `LiveCounter.create(5)` | `LiveCounter.create(initialCount: 5)` |
| `LiveMap.create()` | `LiveMap.create()` |
| `LiveMap.create({ a: 1, b: "x" })` | `LiveMap.create(entries: ["a": 1, "b": "x"])` — entries are `[String: LiveMapValue]`, literals convert |
| a raw string/number/bool/JSON into `set` | pass the literal directly: `set(key: "name", value: "alice")`, `set(key: "n", value: 42)`, `set(key: "cfg", value: ["depth": 2])` |
| a raw **binary** value into `set` | no literal form — `set(key: "blob", value: .primitive(.data(someData)))` |
| a non-literal Swift value (e.g. a `String` variable) | `.primitive(.string(s))` / `.primitive(.number(d))` etc. (or construct the `Primitive` and wrap) |
| creation value into `set` | `.liveCounter(.create(initialCount: 5))` / `.liveMap(.create(entries: …))` |

Inspect a constructed `LiveMapValue` with its convenience getters (`stringValue`, `numberValue`,
`boolValue`, `dataValue`, `jsonObjectValue`, `jsonArrayValue`, `liveMapValue: LiveMap?`,
`liveCounterValue: LiveCounter?`) when a spec asserts on a value's contents.

> **Type-safety turns several "invalid input" spec cases into compile errors, not runtime
> assertions.** Where a spec feeds a deliberately wrong type and expects an `ErrorInfo`, the Swift
> signatures reject it at compile time, so the test isn't expressible — note it as a deviation
> rather than forcing it:
> - Passing a **graph object / public view** (`PathObject`, `Instance`, a live object) as a map
>   value (`RTLMV4c1`, runtime `40013` in the dynamic API) — blocked by the `LiveMapValue` enum.
> - **Wrong-typed `create` args**, e.g. `LiveCounter.create("not_a_number")` (spec expects
>   `40003`) — blocked by `create(initialCount: Double)`; `LiveMap.create(entries:)` likewise
>   takes `[String: LiveMapValue]`, so non-`Dict` / non-`String`-key / unsupported-value entry
>   cases (`RTLMV4a`/`b`/`c`) can't be constructed either.
>
> Validation cases on *values the type system still allows* (e.g. NaN / out-of-range `Double`)
> remain real runtime assertions — only the cases the signature outright forbids become deviations.

---

## 7. Mutations (set / remove / increment / decrement) <a id="7-mutations"></a>

Putting §4 + §6 together — the canonical write translations:

```text
# spec
AWAIT root.set("count", LiveCounter.create(0))
AWAIT root.get("count").increment(5)
AWAIT root.set("name", "alice")
AWAIT root.remove("name")
```
```swift
// ably-cocoa (root is `any LiveMapPathObject`)
try await root.set(key: "count", value: .liveCounter(.create()))
try await root.get(key: "count").asLiveCounter().increment(amount: 5)
try await root.set(key: "name", value: "alice")
try await root.remove(key: "name")
```

- `set` / `remove` live on `LiveMapPathObject` (or `LiveMapInstance`); navigate + `asLiveMap()`
  first unless you're on the root or an already-typed map view.
- `increment` / `decrement` live on `LiveCounterPathObject` (or `LiveCounterInstance`);
  `asLiveCounter()` first.
- Default-amount forms exist: `increment()` ≡ `increment(amount: 1)`, `decrement()` ≡
  `decrement(amount: 1)`.

### Wrong-type write failures still go *through* the cast

A common spec shape is a write on the wrong kind of object, expecting a runtime error — e.g.
`AWAIT root.increment(5) FAILS WITH error` (increment on a map) or `counter.set("k", v) FAILS WITH
error`. In the dynamic API every method exists on every `PathObject`, so the call is expressible
and throws at runtime. In ably-cocoa the typed view **doesn't have that method at all**
(`LiveMapPathObject` has no `increment`; `LiveCounterPathObject` has no `set`), so calling it
directly is a *compile* error — not the runtime failure the spec is testing.

To translate these, cast to the view whose write method you need (the `PathObject` cast never
throws, `RTTS5d`), then assert the **operation** throws — that's where the `92007` surfaces:

```text
# spec: increment on a map fails
AWAIT root.increment(5) FAILS WITH error   # code 92007
```
```swift
do {
    try await root.asLiveCounter().increment(amount: 5)
    Issue.record("expected increment on a map to throw")
} catch {
    #expect(error.code == 92007)    // typed throws: `error` is already ARTErrorInfo
}
```

So "can't call increment on a map" is **not** "not expressible" — it's
`asLiveCounter().increment(...)` plus an assertion on the throw. (Contrast §6: invalid *value* /
*argument-type* cases genuinely aren't expressible, because the enum/`create` signatures reject
them at compile time. Contrast also §5: a wrong `Instance` **cast** is unrepresentable — but a
wrong-type *write* through a path view stays translatable via this pattern.)

---

## 8. Subscriptions, listeners & events <a id="8-subscriptions"></a>

ably-js passes a closure and gets back a `Subscription` with `.unsubscribe()`. ably-cocoa is the
same shape — closures, no listener interfaces — plus an `AsyncStream` variant:

| Spec / ably-js | ably-cocoa |
|---|---|
| `sub = pathObj.subscribe((event) => { … })` | `let sub = try pathObj.subscribe { event in … }` |
| `pathObj.subscribe(listener, { depth: 2 })` | `try pathObj.subscribe(options: .init(depth: 2)) { event in … }` (nil options = default) |
| `sub = instance.subscribe((event) => { … })` | `let sub = try mapOrCounterInstance.subscribe { event in … }` (`InstanceSubscriptionEvent`) |
| `sub.unsubscribe()` | `sub.unsubscribe()` (idempotent, `SUB2b`) |
| `event.object` | `event.object` — `any PathObject` (path sub) / `Instance` (instance sub) |
| `event.message` | `event.message` → `ObjectMessage?` (§11) |
| — Swift-only alternative — | `for await event in try pathObj.events() { … }` / `instance payloads' events()` — an `AsyncStream` that unsubscribes on stream termination. Prefer the closure form when translating (it matches the spec's shape 1:1); the stream form is fine where a spec loops over events. |

Callback typealiases: `PathObjectSubscriptionCallback = @Sendable (PathObjectSubscriptionEvent) ->
Void`, `InstanceSubscriptionCallback = @Sendable (InstanceSubscriptionEvent) -> Void`. Both events
carry only `object` + `message` — there is **no per-key diff** on the public event (see the
`LiveObjectUpdate` note below). Because the callbacks are `@Sendable`, collect results with the UTS
harness's `Captured<T>` (see the main skill's Captured section), not a bare `var`.

`subscribe` **throws** (`RTO25` precondition; also `40003` for a non-positive `depth`,
`RTPO19c1`) — so `try` it, and translate a `FAILS WITH` on subscribe as a do/catch (§12).

> **`LiveObjectUpdate` is not the public event.** `live_object_subscribe.md` cites the internal
> `RTLO4b` `LiveObjectUpdate` (fields `update` / `noop` / `objectMessage` / `tombstone`), but it
> subscribes through the *public* `instance.subscribe(...)`, whose Swift event is
> `InstanceSubscriptionEvent` — only `object` + `message`, **no diff/`noop`/`tombstone`
> accessors**. So "listener fired N times" and "returns a `Subscription`" translate directly, but
> any assertion on the `LiveObjectUpdate` *diff* fields is internal (§13) — adapt or skip with a
> deviation.

---

## 9. Sync-state events (`object.on('synced')`) <a id="9-sync-state"></a>

The ably-js string-event API becomes an enum + closure on `RealtimeObject` (`RTO18`). Note the UTS
pseudocode writes the events as **bare constants**, not strings —
`channel.object.on(SYNCED, () => events.append("SYNCED"))` (`realtime_object.md`):

| Spec / ably-js | ably-cocoa |
|---|---|
| `channel.object.on(SYNCED, cb)` / ably-js `on('synced', cb)` | `let sub = channel.object.on(event: .synced) { … }` → `any StatusSubscription` |
| `channel.object.on(SYNCING, cb)` / `on('syncing', cb)` | `channel.object.on(event: .syncing) { … }` |
| `channel.object.off(cb)` | `sub.off()` — deregistration is **per-subscription** (`RTO18f`); there is no `off(listener)` |
| remove all (`offAll()`) | **No `offAll()` in ably-cocoa.** Call `off()` on each retained `StatusSubscription`; if a spec's assertion depends on a true remove-all, flag a deviation. |

`ObjectsEvent` cases: `.syncing`, `.synced`. The `on` callback takes no payload
(`@Sendable () -> Void`). Note `on(event:callback:)` does **not** throw, unlike `subscribe` (§8).

---

## 10. `ValueType` & type discrimination <a id="10-valuetype"></a>

ably-js uses string-literal type tags; ably-cocoa has `enum ValueType` (`RTTS2`):

| Spec value category | `ValueType` case |
|---|---|
| string / number / boolean / binary | `.string` / `.number` / `.boolean` / `.binary` |
| JSON object / JSON array | `.jsonObject` / `.jsonArray` |
| live map / live counter | `.liveMap` / `.liveCounter` |
| present but unrecognised | `.unknown` |

`try pathObj.type()` returns `ValueType?` — nil when nothing resolves (distinct from `.unknown`);
`instance.type` is non-optional. Use `type()` for "what is it" assertions, then the matching `as*`
view (path) or `case` (instance) to read the value. Translate string tags mechanically:
`"LiveMap"`→`.liveMap`, `"number"`→`.number`, etc.

---

## 11. Message / operation types <a id="11-messages"></a>

The spec's `PublicAPI::ObjectMessage` / `PublicAPI::ObjectOperation` (the `PAOM*` / `PAOOP*` types,
delivered to subscription listeners) map to ably-cocoa **structs with plain `var` properties**
(`Path Based API/Public/PublicObjectMessage.swift`). The `PublicAPI::` prefix is dropped — they are
exposed as `ObjectMessage` / `ObjectOperation` (their internal wire namesakes live under the
`ProtocolTypes` namespace and are invisible to importers).

**The Swift structs have public
memberwise initializers** — a spec that constructs an expected message for comparison can build one
directly and use `==` (everything here is `Equatable`). What ably-cocoa does *not* expose is the
`PAOM3`/`PAOOP3` construction-from-wire (`fromObjectMessage` / `fromObjectOperation`) — that
conversion is internal, so `public_object_message.md`'s from-wire cases need internal access (§13).

`ObjectMessage` properties: `id: String?`, `clientId: String?`, `connectionId: String?`,
`timestamp: Date?`, `channel: String`, `operation: ObjectOperation`, `serial: String?`,
`serialTimestamp: Date?`, `siteCode: String?`, `extras: [String: JSONValue]?`.
**Timestamps are `Date`, not epoch millis** — a spec's numeric timestamp `N` compares as
`Date(timeIntervalSince1970: N / 1000)` (or assert on
`timestamp?.timeIntervalSince1970` × 1000).

`ObjectOperation`: `action: ObjectOperationAction`, `objectId: String`, and optional payloads —
`mapCreate`, `mapSet`, `mapRemove`, `counterCreate`, `counterInc`, `objectDelete`, `mapClear` —
exactly one non-nil, matching the action.

**The spec accesses these as dotted property chains and compares `action` to a *string literal*;
ably-cocoa uses the same property chains but an *enum case*:**

```text
# spec
ASSERT msg.operation.action == "MAP_SET"
ASSERT msg.operation.mapSet.key == "name"
ASSERT msg.operation.mapSet.value.string == "blue"
ASSERT msg.operation.counterInc.number == 42
ASSERT msg.operation.mapCreate == null
```
```swift
let op = msg.operation
#expect(op.action == .mapSet)                 // string "MAP_SET" -> enum case
#expect(op.mapSet?.key == "name")
#expect(op.mapSet?.value.string == "blue")    // ObjectData.string
#expect(op.counterInc?.number == 42)          // Double; literal converts
#expect(op.mapCreate == nil)
```

String action tags map SCREAMING_SNAKE → lowerCamel: `"MAP_SET"`→`.mapSet`,
`"COUNTER_INC"`→`.counterInc`, `"OBJECT_DELETE"`→`.objectDelete`, `"MAP_CLEAR"`→`.mapClear`, etc.
Same rule for semantics (`"lww"`→`.lww`) and value types (§10).

| Spec type | ably-cocoa | Notable members |
|---|---|---|
| `ObjectOperationAction` | `enum ObjectOperationAction` | `.mapCreate, .mapSet, .mapRemove, .counterCreate, .counterInc, .objectDelete, .mapClear` — **no `.unknown` case**; a spec asserting an `UNKNOWN` action is a deviation |
| `MapSet` | `struct MapSet` | `key: String`, `value: ObjectData` |
| `MapRemove` | `struct MapRemove` | `key: String` |
| `MapCreate` | `struct MapCreate` | `semantics: ObjectsMapSemantics`, `entries: [String: ObjectsMapEntry]` (non-optional) |
| `CounterCreate` | `struct CounterCreate` | `count: Double` |
| `CounterInc` | `struct CounterInc` | `number: Double` |
| `ObjectDelete` / `MapClear` | empty structs | no members (assert non-nil-ness) |
| `ObjectData` (leaf value) | `struct ObjectData` | `objectId: String?`, `encoding: String?`, `boolean: Bool?`, `bytes: Data?`, `number: Double?`, `string: String?`, `json: String?` — **`json` is a JSON-encoded `String`**, not a parsed value; decode before structural assertions |
| `ObjectsMapEntry` | `struct ObjectsMapEntry` | `tombstone: Bool?`, `timeserial: String?`, `serialTimestamp: Date?`, `data: ObjectData?` |
| map semantics | `enum ObjectsMapSemantics` | `.lww` only — **no `.unknown`** (deviation if a spec needs it) |

> Note `PublicAPI::ObjectOperation` carries only `mapCreate`/`counterCreate` (the `*WithObjectId`
> outbound variants are resolved back to their `MapCreate`/`CounterCreate` forms, `PAOOP1`). Don't
> expect a `mapCreateWithObjectId` on the public type — those exist only on the internal
> `ProtocolTypes` wire types.

---

## 12. Errors & error codes <a id="12-errors"></a>

Spec assertions like `FAILS WITH error code 92007` map to `ARTErrorInfo`. Everything in this API
uses **typed throws** (`throws(ARTErrorInfo)`), so in a `catch` block `error` *is* the
`ARTErrorInfo` — no casting, no future unwrapping:

```swift
do {
    _ = try await channel.object.get()
    Issue.record("expected get() to throw")
} catch {
    #expect(error.code == 40024)
}
```

| Spec failure | ably-cocoa |
|---|---|
| async op rejects with `ErrorInfo` code N | `try await` throws `ARTErrorInfo`; do/catch and assert `error.code == N` |
| wrong write method for the type (e.g. `increment` on a map, `set` on a counter) | the typed view lacks the method — cast first (`asLiveCounter()` / `asLiveMap()`, never throws, `RTTS5d`), then the **operation** throws `92007`. See §7 |
| `Instance` cast on wrong type (`RTTS9d`) | **not expressible** — `Instance` is an enum; the mismatch case doesn't exist. Deviation. |
| `PathObject` `as*` cast on wrong type | **never throws** (`RTTS5d`) — failure shows up on the subsequent read (nil) or write (throws) |
| invalid value into `set` (graph object / view; `RTLMV4c1`, `40013`) | not expressible in the typed `set` — deviation (§6) |
| non-positive subscription `depth` (`RTPO19c1`) | `subscribe(options: .init(depth: 0))` — the `subscribe` call throws `40003` |
| write where path doesn't resolve | `92005` |
| write where value isn't the required type | `92007` |
| `get()` / op when channel lacks the object mode (`RTO23a`/`RTO2a2`) | `40024` |
| access methods when channel is DETACHED or FAILED (`RTO25b`) | `90001` |
| `get()` when channel is FAILED (`RTO23e`/`RTL33c`) | `90001`. **But `get()` on a DETACHED channel does *not* throw** — ensure-active-channel re-attaches and `get()` resolves (`RTO23e`/`RTL33b`); only the access methods gate on DETACHED |
| channel enters DETACHED/SUSPENDED/FAILED while awaiting SYNCED (`RTO20e`/`RTO23c`) | `92008` |
| write while `echoMessages` is false (`RTO26c`) | `40000` |

Assert the code as a plain `Int` — `#expect(error.code == 90001)` — matching the spec's
`error.code == 90001`; error codes are int literals, not enums (unlike the action / semantics /
value-type tags). The `90000` a spec injects via a mocked `ERROR`/`DETACHED` `ProtocolMessage` is
the channel-level error, not an objects code — it's what drives the channel into the state that
makes the objects call fail.

**Nested cause (`error.cause.code`).** A spec's nested `error.cause.code` (e.g. `RTO20e`:
top-level `92008` plus cause `90000`): `ARTErrorInfo` has no public typed `cause` accessor —
inspect the underlying `NSError` chain (`error.userInfo[NSUnderlyingErrorKey]`) and verify what the
implementation actually populates **at translation time** (the implementation doesn't exist yet —
see the runtime-status warning at the top). If the cause isn't reachable, assert the top-level code
and flag the cause assertion as a deviation.

---

## 13. Internal-graph types (unit specs) — important caveats <a id="13-internal-graph"></a>

Several **unit** specs assert on the **internal CRDT graph**, not the public API:
`InternalLiveCounter.data`, `InternalLiveMap.siteTimeserials`, `ObjectsPool.syncState`,
`LiveObjectUpdate`, `applyOperation(msg, source)`, object-id generation (`RTO14`), the
`*CreateWithObjectId` wire variants, etc. Specs that are wholly or mostly internal:

- `objects_pool.md`, `parent_references.md`, `object_id.md` — pool sync state, the reverse
  parent-reference graph, object-id generation: entirely internal.
- the internal-state assertions in `internal_live_counter*.md` / `internal_live_map*.md` (`.data`,
  `.siteTimeserials`, `.createOperationIsMerged`, `.isTombstone`, `applyOperation`, `replaceData`)
  — internal; their public-facing read/write counterparts are the `path_object*.md` /
  `instance.md` specs.
- `value_types.md` — the *public* `LiveMap.create` / `LiveCounter.create` surface maps via §6, but
  the evaluation half (`COUNTER_CREATE` / `MAP_CREATE` `ObjectMessage` generation,
  nonce/`initialValue`/`objectId` derivation, the `*WithObjectId` wire forms) is
  internal/wire-level.
- `realtime_object.md` — **mixed**: `get()` (`RTO23`, incl. the `40024`/`90001`/`92008`
  precondition cases) is public and maps via §2/§12, but `publish` / `publishAndApply`
  (`RTO15`/`RTO20`, marked `internal` in the IDL) and the OBJECT/ACK wire assertions are internal.
- `public_object_message.md` — the public getters map via §11, but the `PAOM3`/`PAOOP3`
  construction-from-wire is internal (`ProtocolTypes.InboundObjectMessage` → public
  `ObjectMessage`); translating it needs the internal access described below.

In ably-cocoa the internal layer lives in the **same module** (`AblyLiveObjects`,
`Internal/` + `Protocol/` directories: `InternalDefaultLiveMap`, `InternalDefaultLiveCounter`,
`InternalDefaultRealtimeObjects`, `ObjectsPool`, and the `ProtocolTypes.*` wire types) with
`internal` access — no reflection tricks needed, but reachable only via
`@testable import AblyLiveObjects` (that's how the plugin's own test suite,
`LiveObjects/Tests/AblyLiveObjectsTests`, accesses them).

**One-time wiring** — item 1 is
**done**; item 2 is still outstanding and blocks the **unit tier only**:

1. ✅ **The UTS target depends on `AblyLiveObjects`** (done, 2026-07-17, with the integration-tier
   translation). `Package.swift`'s `UTS` test target lists `.target(name: "AblyLiveObjects")`.
   Both feared interactions resolved cleanly: the Swift 6 language mode compiles the fully
   `Sendable` LiveObjects API without friction, and **no `@available` annotations are needed** in
   UTS test code — SPM raises the effective deployment target of test targets above the package
   floor (verified: `swift build --build-tests` clean with unannotated suites).
2. **The spec helpers have no Swift implementation.** Every objects unit spec opens with
   `setup_synced_channel` and builds messages with `build_*` helpers, all fully specified in
   `uts/objects/helpers/standard_test_pool.md` — implement from that document.
   Author the Swift implementation at `Test/UTS/infra/unit/objects/` (e.g. a
   `SyncedChannel` scoped-resource helper on top of `UTSTestCase`'s mock transport, for both
   `setup_synced_channel` and `setup_synced_channel_no_ack`; builders for the full
   `standard_test_pool.md` set — `buildObjectSyncMessage` / `buildObjectMessage` /
   `buildAckMessage` / `buildCounterInc` / `buildMapSet` / `buildMapRemove` / `buildMapClear` /
   `buildObjectDelete` / `buildCounterCreate` / `buildMapCreate` / `buildObjectState` /
   `buildObjectMessageWithState` / `buildPublicObjectMessage` (the last performs the §11
   from-wire construction, so it lives behind `@testable import`); the inline ObjectData /
   map-entry / state fragment helpers (`dataString` / `dataNumber` / `dataBoolean` /
   `dataObjectId` / `dataBytes` / `dataJson`, `mapEntry`, `mapState`, `counterState`,
   `mapCreateOp`, `counterCreateOp`); the `STANDARD_POOL_OBJECTS` fixture; and the canonical
   serial constants `POOL_SERIAL` / `ackSerial(msgSerial:i:)` / `remoteSerial(i:)` /
   `belowAckSerial(i:)`) — the spec's snake_case names, camelCased. **Call helpers; never
   hand-roll the mock setup, message JSON, or `"t:N"` serial literals** (serials compare as
   strings — ad-hoc values silently sort wrong).

Spec name → ably-cocoa impl (for orientation, not public use): `InternalLiveMap` →
`InternalDefaultLiveMap`, `InternalLiveCounter` → `InternalDefaultLiveCounter`, the public-view
impls are `DefaultLiveMapPathObject` / `DefaultLiveCounterInstance` / … (`Path Based API/Default/`,
currently all `notImplemented()`), wire forms are `ProtocolTypes.ObjectMessage` /
`WireObjectMessage` / `WireObjectOperation` etc.

> **Runtime status recap (top of doc):** the path-based public surface **traps**
> (`notImplemented()`). Internal-layer specs may be runnable earlier
> than public-API specs (the internal CRDT machinery predates the path-based API and has a passing
> test suite in `AblyLiveObjectsTests`), but check what the spec actually calls before choosing
> evaluate mode.

---

## 14. Integration-test helpers — REST fixture provisioning <a id="14-integration-helpers"></a>

Some objects **integration** specs (tier `integration/standard`) seed object state over REST
*before* the realtime client connects, via the spec's `## REST Fixture Provisioning` helper
`provision_objects_via_rest` (`standard_test_pool.md`).

**Implemented** at `Test/UTS/integration/standard/objects/helpers/ObjectsRestProvisioning.swift`
(module helpers live in a `helpers/` directory next to the module's suites, not under the
module-agnostic `infra/`; shared client/channel wiring and `value()` read helpers sit alongside in
`ObjectsIntegrationHelpers.swift`):
`provisionObjectsViaRest(apiKey:channelName:operations:) -> [String]` plus the op/value builders
(`mapSetOp`, `mapRemoveOp`, `mapCreateOp`, `counterCreateOp`, `counterIncOp`; `valueString`,
`valueNumber`, `valueBoolean`, `valueBytes`, `valueObjectId`). Two facts the implementation
encodes (hard-won — don't re-derive them):

- **V2 REST format** (OpenAPI is the source of truth): `POST /channels/{channel}/object`
  (**singular**), body is a single operation **or** a bare array (no `messages` wrapper), each op
  named by its payload key (`mapSet` / `mapRemove` / `mapCreate` / `counterInc` / `counterCreate`)
  with an `objectId`/`path` target and optional idempotency `id`. The spec's legacy
  `POST …/objects` + `{ messages: [...] }` shape was aligned to V2 in ably/specification#497.
- **Sandbox host**: use `SandboxApp.sandboxHost` (`sandbox.realtime.ably-nonprod.net`,
  `Test/UTS/infra/integration/SandboxApp.swift`) — the same nonprod host every UTS integration
  client uses; do not use the legacy `sandbox-rest.ably.io`.

Implementation details settled by the port (don't re-derive them):

- `operations` must be non-empty (`precondition`).
- **Response parsing**: the body is a single result object *or* a JSON array of them, each carrying
  an `objectIds` string array; the helper flattens those into its `[String]` return. The UTS spec
  helper documents no response contract — flagged upstream.
- The cocoa port posts through the UTS infra's plain `URLSession` helpers
  (`jsonRequest`/`httpRequest`, `infra/Utils.swift`) rather than an `ARTRest` client, so the spec's
  "REST client must be closed after use" note doesn't apply here.

The realtime client then observes the provisioned data through OBJECT_SYNC +
`channel.object.get()` — which requires the path-based implementation, so these specs are gated on
the runtime status like everything else.

**The GC spec** (`objects_gc_test.md`, RTO10/RTLM19 tombstone semantics) needs no extra infra, but
it is the only integration spec that reads `instance().id` (hence `counterInstanceId(at:)` in
`ObjectsIntegrationHelpers.swift`, §5).

**Sandbox-app scoping.** The `IntegrationTestCase` pattern provisions per test via
`withSandboxApp`, so each parameterised case (×2 protocol variants) creates and deletes its own
app. Deliberate — Swift Testing has no suite-level async fixtures — but keep it in mind if sandbox
provisioning ever becomes a bottleneck.

**Proxy tier.** The objects module also has a proxy spec
(`integration/proxy/objects_faults.md`) — fault injection against `channel.object.get()` and
friends. Nothing objects-specific is needed for the proxy *infrastructure*: use the main skill's
proxy tier (session/rules/actions, `AuthReauthTests.swift` as the reference) and this doc purely
for the API mapping.

---

## 15. Worked example <a id="15-worked-example"></a>

Spec pseudocode (public-API style):

```text
test "increments a nested counter and observes it"
  root = AWAIT channel.object.get()
  AWAIT root.set("game", LiveMap.create({ score: LiveCounter.create(0) }))
  scoreSub = root.at("game.score").subscribe((event) => { received = event })
  AWAIT root.at("game.score").increment(10)
  ASSERT root.at("game.score").value() == 10
  ASSERT received.object.value() == 10
  scoreSub.unsubscribe()
```

ably-cocoa / Swift translation:

```swift
let root = try await channel.object.get()   // `any LiveMapPathObject`

try await root.set(
    key: "game",
    value: .liveMap(.create(entries: ["score": .liveCounter(.create())]))
)

let received = Captured<PathObjectSubscriptionEvent>()   // @Sendable callback -> harness collector
let scoreSub = try root.at(path: "game.score").subscribe { event in
    received.append(event)
}

try await root.at(path: "game.score").asLiveCounter().increment(amount: 10)

#expect(try root.at(path: "game.score").asLiveCounter().value() == 10)
#expect(try #require(received.all.last).object.asLiveCounter().value() == 10)
scoreSub.unsubscribe()
```

Note the mechanical rewrites: `AWAIT` → `try await` (no future); nested creation via the
`.liveMap(.create(entries:))` / `.liveCounter(.create())` enum cases (primitive literals would need
no wrapper at all); `at(...)` followed by `asLiveCounter()` before counter ops; the `@Sendable`
listener capturing through `Captured`; `event.object` re-cast with `asLiveCounter()`.

---

## 16. Quick symbol index <a id="16-symbol-index"></a>

| ably-js / spec symbol | ably-cocoa |
|---|---|
| `channel.object` | `channel.object: any RealtimeObject` (property) |
| `channel.object.get()` | `try await channel.object.get()` → `any LiveMapPathObject` |
| `PathObject` (polymorphic) | `PathObject` protocol + `asLiveMap()` / `asLiveCounter()` / `asPrimitive()` (3 views, not 8) |
| `Instance` (polymorphic) | `enum Instance { .liveMap / .liveCounter / .primitive }` — `switch`, no casts |
| `pathObj.path()` | `pathObj.path` (property) |
| `pathObj.get(k)` / `.at(p)` | `pathObj.asLiveMap().get(key: k)` / `.at(path: p)` |
| `pathObj.value()` | counter: `asLiveCounter().value()` → `Double?`; primitive: `asPrimitive().value()?.numberValue` etc. |
| `pathObj.set(k, v)` / `.remove(k)` | `try await pathObj.asLiveMap().set(key: k, value: v)` / `.remove(key: k)` |
| `pathObj.increment(n)` / `.decrement(n)` | `try await pathObj.asLiveCounter().increment(amount: n)` / `.decrement(amount: n)` |
| `op FAILS WITH <code>` (wrong method for type) | cast to the needed view, do/catch the op, `#expect(error.code == <code>)` (§7, §12) |
| `FOR [k, v] IN x.entries()` | `for (k, v) in try x.asLiveMap().entries()` |
| `"k" IN x.keys()` / `list(x.keys())` | `try x.asLiveMap().keys().contains("k")` / `try x.asLiveMap().keys()` |
| `size() == 7` / `== null` | `#expect(try …size() == 7)` (`Int?`) / `#expect(try node.asLiveMap().size() == nil)` |
| `op.action == "MAP_SET"` | `#expect(op.action == .mapSet)` (string tag → enum case, lowerCamel) |
| `op.mapSet.value.string` | `op.mapSet?.value.string` (`ObjectData` properties) |
| `LiveMap.create(entries)` | `LiveMap.create(entries: [String: LiveMapValue])` (value type) |
| `LiveCounter.create(n)` | `LiveCounter.create(initialCount: n)` (value type) |
| raw value into `set` | literals pass directly (`ExpressibleBy*Literal`); non-literals via `.primitive(.string(s))` etc.; binary always `.primitive(.data(d))` |
| `subscribe(cb)` → `Subscription` | `try subscribe { event in … }` → `any Subscription` (also `events()` AsyncStream) |
| `{ depth: n }` | `PathObjectSubscriptionOptions(depth: n)` |
| `event.object` / `event.message` | `event.object` / `event.message: ObjectMessage?` |
| `object.on('synced', cb)` | `channel.object.on(event: .synced) { … }` → `any StatusSubscription`; `off()` per subscription (no `off(listener)`/`offAll`) |
| type tag `'LiveMap'` etc. | `ValueType.liveMap` etc.; `type()` optional on paths, `type` non-optional on instances |
| `PublicAPI::ObjectMessage` | `struct ObjectMessage` (properties + public init; timestamps are `Date`) |
| `PublicAPI::ObjectOperation` | `struct ObjectOperation` (one payload non-nil; no `.unknown` action) |
| `InternalLiveMap` / `InternalLiveCounter` / `ObjectsPool` | `internal` in `AblyLiveObjects` — `@testable import` + UTS-target dependency wiring, §13 |
| `setup_synced_channel` / `build_*` / `provision_objects_via_rest` | **no Swift impl yet** — author per §13/§14 before first use |
