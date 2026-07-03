# Review: LiveObjects path-based Swift public API (ably-cocoa#2218)

Review of the proposed path-based LiveObjects Swift public API in **ably-cocoa#2218** (AIT-1023), read as a change to the public surface of the **ably-liveobjects-swift-plugin** repo.

## Sources consulted

| Source | Version consulted |
|---|---|
| ably-cocoa#2218 (the PR under review) | branch `ably-liveobjects-swift-exp`, head `992c6982`; PR is a **draft**, base `main`. Description and inline review comments (Sachin, Lawrence, Marat, CodeRabbit) read as of 2026-07-03. Sachin's review comments reiterate the spec #491 / AIT-1023 points already covered below (notably that `instance()` should be a Swift enum, §2, and that `PathObject` needs a `type`/`getType`, §3). |
| ably-liveobjects-swift-plugin (current public API) | `main` @ `a3bf63d` |
| specification #491 — *Add typed-SDK LiveObjects API spec section (RTTS1–RTTS10)* | branch `feature/liveobjects-cross-sdk-types-spec` @ `9d4ad947` (PR last updated 2026-06-18); **treated as source of truth for the typed-SDK shape** |
| specification #485 (main path-based changes) | `integration/liveobjects-path-based-api-ditch-merge-commits` @ `7ba0b8f8` |
| specification #489 (type renames) | `rename/liveobjects-map-counter-interfaces` @ `a335a3d6` |
| ably-js (canonical dynamic implementation) | `main` @ `503a39d8` (`liveobjects.d.ts` + `src/plugins/liveobjects/`) |
| ably-java (sibling strongly-typed implementation) | `origin/feature/path-based-liveobjects-implementation` @ `e2ad9b58` |
| Confluence — *Final Assessment of the LiveObjects Path-Based API for Java and Swift* | page `5127372801`, **version 34** (author Sachin Shinde), fetched 2026-07-03; inline + footer comment threads read up to 2026-06-25. The load-bearing design decisions live in **inline-comment reply threads**, not the page body — the specific comments taken into account are enumerated in **Appendix A**. |
| ably-liveobjects-swift-plugin#128 (Lawrence's original Swift proposal) | branch `2025-12-09-path-based-api-proposal`, head `7f8cec1c` (`PATH-BASED-API.md`, `PublicTypes.swift`, `example.swift`) |
| AIT-1023 comment on the `Instance` enum decision | provided inline in the review brief; **treated as authoritative** |

Where sources conflict, the resolution used is stated inline (see especially §2).

---

## 1. Headline

The proposal is a clean, readable first cut that gets the **skeleton, naming, `throws`/`async`/`Sendable` annotations, value types, and the `ObjectMessage` port broadly right**. However, it was written from a narrow source base — the PR description shows the IDL was the author's own sketch derived from specification #485/#489 and the public docs, and it did **not** consult spec #491, the Confluence "Final Assessment" page, plugin PR #128, or the AIT-1023 `Instance` decision. As a result it misses several **decided** elements of the typed-SDK design:

1. **`instance()` does not return the decided `Instance` enum** (AIT-1023). It returns a loosely-typed `any Instance` with `as*` narrowing — the opposite of the authoritative decision. **(§2 — most important.)**
2. **`getType()`, `exists()` and the `ValueType` enum are entirely absent** (spec RTTS2/RTTS4). **(§3)**
3. **Typed `Instance` accessors are wrongly optional.** `compactJson`, `size`, and `value` on the typed instances must be **non-optional** per RTTS7a/RTTS10 and the explicit AIT-1023/PR#128 decision that an `Instance`'s type is known once it is held. **(§4)**
4. **The six primitive sub-types are collapsed to one `Primitive`.** Defensible and aligned with the AIT-1023 direction, but it diverges from spec RTTS6c/RTTS10c and from ably-java, so it needs explicit cross-SDK sign-off. **(§5)**
5. **The `as*` narrowing methods are declared in protocol extensions**, so they are not customisation points and (on `Instance`) have no defined mismatch behaviour. **(§6)**

Two plugin decisions were silently reversed: subscription self-deregistration (§9) and the property-vs-method convention (§8).

The `throws`/`async`/`Sendable` annotations are, by contrast, largely **correct** and well-reasoned (§7).

---

## 2. `instance()` return type — the central divergence

**Authoritative decision (AIT-1023):** `PathObject.instance()` should return a Swift **enum**, to allow exhaustive checking:

```swift
enum Instance {
  case liveMap(LiveMapInstance)
  case liveCounter(LiveCounterInstance)
  case primitive(PrimitiveInstance)
}
```

**Proposal:** `Instance` is a `protocol`; `instance()` returns `(any Instance)?`; discrimination is via `asLiveMap()` / `asLiveCounter()` / `asPrimitive()`.

This is the single most significant departure. It matters because:

- **It contradicts the authoritative source.** The enum was chosen specifically to give callers a compile-time-exhaustive `switch` over the three instance kinds; the `any Instance` + `as*` model gives neither exhaustiveness nor a safe mismatch path.
- **There is a genuine source tension, and the proposal resolved it the wrong way.** Spec #491 (RTTS9), the Confluence page, ably-java and PR #128 all use base-type + `as*` casts. The AIT-1023 comment is the later, Swift-specific decision that overrides them *for Swift's `Instance`*. The proposal followed the language-agnostic sources rather than the Swift-specific decision. (Note that a single `type()`/`InstanceType`-enum discriminator was itself floated on the Confluence page — comment `5132582914`, Appendix A — as was the open question of whether to drop the inheritance entirely — comment `5134549008`; both point in the same direction as the enum.)
- **`PathObject` is a different case and the proposal is right there.** A `PathObject` is unresolved, so its type is unknown and an enum cannot be returned; `as*` narrowing before resolution is correct and matches spec RTTS5/RTTS3h. The mistake is applying that same `PathObject` pattern to `Instance`, whose type *is* known at construction (RTTS7e).

**Recommendation:** make `instance()` return the enum from AIT-1023. `LiveMapInstance` / `LiveCounterInstance` / `PrimitiveInstance` remain as the payload types, but the `as*` helpers on `Instance` disappear (the `switch` replaces them). If the team now prefers to *revisit* the enum decision in light of spec #491's `as*` model, that should be an explicit, recorded decision rather than an unstated consequence of the sources the PR happened to consult.

---

## 3. Missing surface: `getType()`, `exists()`, `ValueType`

Spec #491 introduces these and they are absent from the proposal:

- **`ValueType` enum (RTTS2)** — `STRING / NUMBER / BOOLEAN / BINARY / JSON_OBJECT / JSON_ARRAY / LIVE_MAP / LIVE_COUNTER / UNKNOWN`.
- **`PathObject.getType() -> ValueType?`** (RTTS4b) — `nil` when nothing resolves at the path.
- **`PathObject.exists() -> Bool`** (RTTS4a) — present in spec RTTS4a; ably-java implements it.
- **`Instance.getType` (RTTS8a)** — non-optional (never `UNKNOWN` in normal operation), and per RTTS8 exposed as a **property** on `Instance`.

`getType()`/`exists()` are the spec's sanctioned way to discriminate a `PathObject`'s type *before* casting (RTTS5e/RTTS9d1). ably-java implements all three. They should be added. (Note: if `instance()` becomes the enum per §2, `Instance.getType` is largely redundant on the instance side, but `PathObject.getType()`/`exists()` are still needed.)

---

## 4. Typed `Instance` accessors must be non-optional

The proposal makes the typed-instance accessors optional, which is incorrect:

| Member | Proposal | Required | Authority |
|---|---|---|---|
| `Instance.compactJson()` | `throws -> JSONValue?` | `throws -> JSONValue` | RTINS11 + **RTINS11c** (universal non-null invariant), RTTS7a |
| `LiveMapInstance.size()` | `throws -> Int?` | `throws -> Int` | RTTS10a (narrowed to non-nullable; RTINS9c cannot trigger for a map) |
| `LiveCounterInstance.value()` | `throws -> Double?` | `throws -> Double` | RTTS10b (narrowed non-null) |
| `PrimitiveInstance.value()` | `throws -> Primitive?` | `throws -> Primitive` | RTTS10c (primitive instances wrap a resolved primitive) |

The root cause is applying `PathObject` nullability semantics to `Instance`. On a `PathObject`, `value()`/`size()`/`compactJson()` are correctly optional (RTPO7/RTPO12/RTPO14 return `nil` on resolution failure/type mismatch) — and the proposal gets those right. But an `Instance` is bound to an already-resolved value of known type (RTTS7e), so its accessors cannot fail to produce a value. This is exactly the point made in both PR #128 ("once you have an `Instance` you should be sure about its type … non-optional") and the Confluence comment thread (comment `5135269889`, Appendix A), and it is what ably-java ships (`@NotNull Long size()`, `@NotNull Double value()`, `@NotNull JsonElement compactJson()`).

Keep the `throws` — the `RTO25` access-precondition check (channel detached/failed, missing `OBJECT_SUBSCRIBE` mode) still applies (RTINS4a, RTINS9a, RTINS11a) — but drop the `?`.

`LiveMapInstance.get(key:) -> (any Instance)?` is correctly optional (RTINS5c — key may be absent). `id` is correctly a non-optional `String` on both map and counter instances, and correctly omitted from the base and from primitives — this matches the Confluence `id` decision exactly (comment `5135269889`, Appendix A: "remove the nullable one from `Instance` and put a non-nullable one on `LiveMapInstance` and `LiveCounter`"). 

---

## 5. Collapsing the six primitive sub-types into one `Primitive`

Spec RTTS6c/RTTS10c mandate **six** primitive sub-types each (`NumberPathObject`, `StringPathObject`, … / `NumberInstance`, `StringInstance`, …), with per-type `as*` helpers (`asNumber`, `asString`, …) and type-filtered `value()`. ably-java implements all twelve.

The proposal instead has a single `PrimitivePathObject`/`PrimitiveInstance` returning a `Primitive` enum, with a single `asPrimitive()`.

This is a reasonable, Swift-idiomatic consolidation (pattern-match a `Primitive` rather than juggle six types) and it aligns with the AIT-1023 direction (a single `primitive(PrimitiveInstance)` case). But note the consequences and get them signed off:

- **Cross-SDK portability.** RTTS1a states that all typed SDKs "must agree on the partition … so that user code is portable." Swift collapsing to one primitive type while Java exposes six is a real divergence in the user's mental model. That Java deliberately went granular (a base `Primitive` optional; per-primitive types required for value retrieval) is recorded on the Confluence page — footer comment `5132091394`, Appendix A. This is Sachin's call as spec-owner — raise it explicitly.
- **Loss of type-filtered accessors.** The spec's `NumberPathObject.value()` returns `nil` unless the resolved value is specifically a number (RTTS6g). A single `Primitive`-returning `value()` instead returns *whatever* primitive resolved — effectively the dynamic RTPO7 behaviour. That's a defensible trade, but it is a semantic change from the spec, not just a renaming.

If the collapse is kept, document it as a deliberate divergence from RTTS6c/RTTS10c.

---

## 6. `as*` methods are declared in protocol extensions

`asLiveMap()`/`asLiveCounter()`/`asPrimitive()` live in `public extension PathObject`/`public extension Instance`, not in the protocol requirement lists. Two consequences:

- **They are statically dispatched and non-overridable.** Called on `any PathObject`/`any Instance`, they always resolve to the extension body — a conformer cannot supply its own. That is only acceptable if the intended design is a single universal implementation that wraps `self` in an internal adapter. If per-conformer behaviour is intended, they must be protocol requirements. Worth confirming the intended dispatch model (everything is `notImplemented()` today, so it isn't yet observable).
- **On `Instance`, the mismatch contract is undefined.** Per RTTS9d an `Instance` `as*` cast must **throw** on a type mismatch (ably-java throws `IllegalStateException`). The proposal's `func asLiveMap() -> any LiveMapInstance` neither throws nor returns optional, so there is no valid behaviour when the underlying type differs. Adopting the enum from §2 removes this problem entirely; if the `as*` model is kept on `Instance`, these must `throws(ARTErrorInfo)`. (On `PathObject`, non-throwing `as*` is correct per RTTS5d — best-effort, never throws on cast.)

---

## 7. `throws` / `async` / `Sendable` — largely correct

**`throws` is accurate.** The proposal marks as `throws(ARTErrorInfo)` exactly those methods that check the `RTO25` access preconditions or `RTO26` write preconditions, and leaves pure navigation non-throwing:

- Throwing reads — `value`, `instance`, `entries`, `keys`, `values`, `size`, `compactJson`, `subscribe` — all correct: RTPO7a/8a/9a/10a/11a/12a/14a and RTPO19b (and the RTINS equivalents) each check `RTO25`. `subscribe` throwing is additionally justified by RTPO19c1a (invalid `depth` → 400/40003).
- Async writes — `set`, `remove`, `increment`, `decrement`, and `RealtimeObject.get()` — correctly `async throws`, matching the `=> io` marker in the IDL and RTO26.
- Non-throwing, non-async — `path()`, `get(key:)`, `at(path:)`, `on(...)`, `offAll()`, `Subscription.unsubscribe()`, `StatusSubscription.off()` — correct: these neither resolve a path nor check preconditions (RTPO4/5/6 have no `RTO25` step).

This resolves the open "can reads throw?" question left hanging in PR #128 and the Confluence footer thread (comment `5132713985`, Appendix A — which asked what `LiveCounterPathObject.value()` does with no counter at the path): the answer the proposal encodes — *reads return `nil`/empty on resolution failure but `throw` on precondition failure* — is the correct reading of the spec, and it matches plugin `main`. Note that spec #491 (RTTS6b) settled that thread in favour of returning `nil` (not throwing) on a type/resolution miss, so the proposal's `Double?` on `LiveCounterPathObject` is right. Worth calling this out explicitly in the PR so the decision is visible.

**`async` is correct** throughout (see above); the read/write split matches the IDL's `=> io` markers.

**`Sendable` is correct.** All public protocols (`PathObject` and sub-protocols, `Instance` and sub-protocols, `RealtimeObject`, `Subscription`, `StatusSubscription`), all value types (`Primitive`, `LiveMapValue`, `LiveMap`, `LiveCounter`, `JSONValue`, `ObjectMessage` and payloads, subscription events/options, all enums), and the callback typealiases (`@Sendable`) are marked `Sendable`. The subscription-event structs holding `any PathObject`/`any Instance` are sound because those protocols are themselves `Sendable`.

---

## 8. Re-litigated decision: properties vs methods

Plugin `main` exposes collection/value accessors as **throwing computed properties** (`var size: Int { get throws }`, `var value: Double { get throws }`, `var entries`, `var keys`, `var values`). PR #128 likewise leaned on properties for O(1), non-side-effecting accessors. The proposal switches **everything to methods** (`size()`, `value()`, `entries()`, …).

The spec makes a property-vs-method ruling in only two narrow places, and both concern the newly-introduced discriminator helpers — not the accessors generally:

- **`PathObject.exists()` / `getType()` should be methods** — RTTS4: "They have O(n) complexity in the path length because they resolve the path at call time, and are therefore exposed as methods (not properties) even in host languages that distinguish the two."
- **`Instance.getType` (RTTS8) and the `Instance` `as*` casts (RTTS9) should be properties** — O(1), because an `Instance` is bound to an already-resolved value.

For every *other* accessor (`value`, `get`, `entries`, `keys`, `values`, `size`, `compactJson`) the spec simply uses method notation (`()`) in the IDL and gives no complexity-based rationale; under the spec's "ergonomic decisions left to implementations" principle that is not a binding property-vs-method ruling. So the proposal's blanket switch to methods is a legitimate ergonomic choice rather than a spec requirement — but it does reverse plugin `main`'s property convention, so it should be a stated decision. The one alignment the proposal should make with the spec is exposing `Instance.getType` and the `Instance` `as*` casts as **properties** (to the extent those members survive the §2 enum decision — the enum removes the `as*` casts and largely subsumes `getType` on the instance side).

---

## 9. Re-litigated decision: subscriptions

Two changes from plugin `main`, both currently unexplained:

- **Self-deregistration from within a listener was dropped.** Plugin `main` deliberately passes the subscription handle into the listener (`LiveObjectUpdateCallback<T> = @Sendable (_ update: sending T, _ subscription: SubscribeResponse) -> Void`) so a listener can unsubscribe itself. The new public callbacks (`PathObjectSubscriptionCallback`, `InstanceSubscriptionCallback`) take only the event. Dropping it aligns with ably-js and the spec (RTPO19e/RTINS16e deliver only the event), so this is probably the right call — but it reverses a deliberate Swift-specific deviation and should be stated. Note the inconsistency that the now-internal `LiveObject` in `InternalTypes.swift` still uses the old self-unsubscribe callback shape.
- **No *public* `AsyncSequence` subscription variant on the new surface.** The one async-sequence helper present — `updates() -> AsyncStream<Update>` — is `internal` (in `InternalTypes.swift`, on the now-internal `LiveObject`) and emits the old `Update` type, not the new `PathObjectSubscriptionEvent`/`InstanceSubscriptionEvent`. In plugin `main` this same `updates()` was **public** (`public extension LiveObject`); so versus `main` the public async-sequence affordance was removed along with `LiveObject`. Meanwhile ably-js exposes `subscribeIterator()` on both `PathObject` and `Instance` (its two data-subscription surfaces; not on the status-event `on`/`off`). So the gap is specifically: the new public `PathObject.subscribe(options:)` and `LiveMapInstance`/`LiveCounterInstance.subscribe()` have no async-sequence form (see §12). No parity gap on `RealtimeObject.on`, since ably-js has no iterator there either.

The subscription plumbing that *is* present is correct: `Subscription.unsubscribe()` (SUB2a/2b) and `StatusSubscription.off()` (RTO18f1) are right; `subscribe` returning `@discardableResult any Subscription` and being `throws` is right; `PathObjectSubscriptionEvent.message` / `InstanceSubscriptionEvent.message` are correctly optional (RTPO19e2/RTINS16e2) while `object` is required, satisfying the RTTS3d/RTTS10a requirement that typed SDKs expose `message`.

---

## 10. Value types, `LiveMapValue`, `JSONValue`, `ObjectMessage` — accurate ports

These are the strongest parts of the PR.

- **`LiveMap` / `LiveCounter` creation value types** (RTLMV/RTLCV): correct. `static create(...)` factories, internal `entries`/`count`, `Sendable`+`Equatable`. The two-overload form (`create()` and `create(initialCount:)`) is a fine Swift rendering of the spec's optional-arg `create`. Naming matches the #489 rename (`LiveMap`/`LiveCounter`, not `…ValueType`).
- **`LiveMapValue`**: correctly narrowed to a **write-only** union — `.primitive(Primitive) | .liveMap(LiveMap) | .liveCounter(LiveCounter)` — matching the RTPO15/RTINS12 set, with the `ExpressibleBy*Literal` conformances preserved for literal ergonomics. This is the right adaptation from plugin `main` (where `LiveMapValue` doubled as a read type and carried live-object references); reads now flow through `PathObject`/`Instance`/`Primitive` instead. Minor: the read-oriented convenience getters (`stringValue`, `numberValue`, …) copied from `main` are vestigial on a write-only type and could be dropped.
- **`JSONValue`**: the **public** surface is unchanged from plugin `main` (identical cases, `ExpressibleBy*Literal` conformances, `isNull`, the `ExpressibleByNilLiteral` doc note, `indirect`, `Sendable`+`Equatable`). Only the plugin's *internal* serialization helpers (`init(jsonSerializationOutput:)`, `toExtendedJSONValue`, `JSONObjectOrArray`, …) were not carried over — expected, and out of scope for a public-API review. Nothing to flag.
- **`ObjectMessage` / `ObjectOperation` (PAOM/PAOOP)**: a faithful port. Field-level optionality matches (`channel` and `operation` required, the rest optional), and the outbound-only `mapCreateWithObjectId`/`counterCreateWithObjectId` variants are correctly resolved away to `MapCreate`/`CounterCreate` (PAOOP1/PAOOP3), as documented in the file. Modelling these as plain `Sendable`/`Equatable` structs is appropriate. **One field to reconsider: `CounterInc.amount` renames the wire/spec field `number`.** The spec's `CounterInc` has a single attribute `number` (CIN2a), and `PublicAPI::ObjectOperation.counterInc` reuses that wire type verbatim (copied, not derived — PAOOP3a), so per the spec the public field is `number`. This is the *only* field in the entire `ObjectMessage`/`ObjectOperation` port that departs from the wire names — the sibling `CounterCreate` keeps `count` (CCR2a), and `ObjectData`/`MapSet`/etc. all keep theirs — so the rename also breaks the port's own faithful-mirror consistency. It's unclear why it was renamed; either a motivation should be stated (and, since this is a user-inspectable mirror of the wire message, ideally raised as a spec-level rename so other SDKs align rather than diverging in Swift alone), or it should stay `number`.

`RealtimeObject` (singular) + `channel.object` + `get() async throws -> any LiveMapPathObject` correctly reflect the #485/#489 renames and RTO23/RTO23f/RTTS6d; `ObjectsEvent` (`.syncing`/`.synced`) matches RTO18b.

---

## 11. Spec-point reference accuracy

Most citations are correct. The systematic issue is that the narrowing/partition points cite the **general** allowance clauses rather than the **specific** typed-SDK clauses — a direct symptom of the PR having been written against #485/#489 before #491 existed:

- `asLiveMap()`/`asLiveCounter()`/`asPrimitive()` on `PathObject` cite `RTPO1a`; the specific clauses are **RTTS5a–c**.
- `asLiveMap()`/etc. on `Instance` cite `RTINS1a`; the specific clauses are **RTTS9a–c**.
- `LiveCounterPathObject.value()` cites `RTPO7`; the type-filtered typed accessor is **RTTS6b** (RTPO7 is the dynamic, non-type-filtered value).
- The typed sub-classes as a whole should reference **RTTS3/RTTS6/RTTS7/RTTS10** rather than only RTPO/RTINS.

Two further points:

- **`ARTRealtimeChannel.object` cites `RTL27`.** `objects-features.md` replaces RTO1 with RTO23 and doesn't name the channel accessor; confirm `RTL27` (in the core features spec) is the right anchor for the channel-side property.
- **`offAll()` (cited as `RTO19`) should be removed, not re-cited.** `offAll` was never in the objects spec. It was copied from ably-js — it existed at `f6fbe35`, the commit the plugin's public API was originally based on (plugin commit `ce8c022f`) — but ably-js has since **deleted** it: its CHANGELOG records *"`RealtimeObject.offAll()` removed; use individual `StatusSubscription.off()` or `RealtimeObject.off(event, callback)` instead"* (and the LiveObject `.on()/.off()/.offAll()` lifecycle trio removed entirely). So it's a doubly-stale vestige — never speced, and since dropped from JS. RTO19 (the citation) is in fact `RealtimeObject#off`, deregister a *specific* listener — which, together with the per-subscription `StatusSubscription.off()` (RTO18f) the proposal already has, is exactly the spec's and JS's replacement for `offAll`. Recommendation: drop `offAll()`; if per-`RealtimeObject` listener removal is wanted, expose `off` per RTO19 instead.

Otherwise the PAOM/PAOOP/operation-payload citations (PAOM2a–j, PAOOP2a–i, MCR/MST/MRM/CCR/CIN/ODE/MCL/OMP2/OME/OD) and the RTINS/RTPO method citations line up.

---

## 12. Opportunities for a more Swift-native API

- **Adopt the `Instance` enum (§2).** Beyond honouring the decision, it gives callers an exhaustive `switch` and removes the undefined-mismatch problem of the `Instance` `as*` casts.
- **`AsyncSequence` subscriptions on `PathObject` and `Instance` (§9).** Add an async-sequence form of `PathObject.subscribe(options:)` (emitting `PathObjectSubscriptionEvent`) and of `LiveMapInstance`/`LiveCounterInstance.subscribe()` (emitting `InstanceSubscriptionEvent`) — the analogue of ably-js's `subscribeIterator` on those two surfaces. The existing internal `updates()` bridge is a useful starting point but emits the old `Update` type, so it would need re-shaping to the new event types. This is idiomatic Swift concurrency and pairs naturally with the `async` write API.
- **Consider `throws` typed accessors as properties where the spec allows** (Instance side, §8) if the team wants the property feel from plugin `main`.
- **`Primitive`/`LiveMapValue` ergonomics**: with `LiveMapValue` now write-only, drop the vestigial read getters (§10) and keep the literal conformances, which are the valuable part.

---

## 13. Comprehensiveness checklist

| Spec area | Status in proposal |
|---|---|
| `PathObject` base: `path`, `instance`, `compactJson`, `subscribe` | Present ✓ |
| `PathObject.exists()` (RTTS4a) | **Missing** |
| `PathObject.getType()` (RTTS4b) | **Missing** |
| `ValueType` enum (RTTS2) | **Missing** |
| `LiveMapPathObject`: `get`, `at`, `entries`, `keys`, `values`, `size`, `set`, `remove` | Present ✓ (correct nullability/throws) |
| `LiveCounterPathObject`: `value`, `increment`, `decrement` | Present ✓ |
| Primitive `PathObject` sub-types (RTTS6c ×6) + `asNumber`/… | Collapsed to `PrimitivePathObject`/`asPrimitive` — divergence (§5) |
| `Instance` base: `compactJson` | Present but wrongly optional (§4); missing `getType` |
| `instance()` returns decided enum (AIT-1023) | **No** — returns `any Instance` + `as*` (§2) |
| `LiveMapInstance`: `id`, `get`, `entries`, `keys`, `values`, `size`, `set`, `remove`, `subscribe` | Present; `size` should be non-optional (§4) |
| `LiveCounterInstance`: `id`, `value`, `increment`, `decrement`, `subscribe` | Present; `value` should be non-optional (§4) |
| Primitive `Instance` sub-types (RTTS10c ×6) | Collapsed to `PrimitiveInstance` — divergence (§5); `value` should be non-optional |
| `subscribe` off base `Instance` (RTTS7b) | Correct ✓ (only on map/counter instances) |
| `compact()` omitted (RTTS3f/RTTS7d) | Correct ✓ |
| `compactJson` narrowing on instance sub-types (RTTS7a) | Not narrowed — permitted (Confluence comment `5135269889`; RTTS7a); but base return must be non-null (§4) |
| `RealtimeObject`: `get`, `on`, `off`/`offAll` | Present ✓ (verify `offAll` vs RTO19, §11) |
| `ObjectMessage` / `ObjectOperation` / payloads (PAOM/PAOOP) | Present ✓, faithful |
| `LiveMap`/`LiveCounter` value types, `LiveMapValue`, `JSONValue` | Present ✓, correct |
| `AsyncSequence` subscription variant | Absent (§9/§12) |

---

## 14. Suggested next step for the PR

The most useful single addition to the PR description would be a short "porting decisions" section that states, for each non-obvious choice, which source it follows: the enum-vs-`as*` decision for `Instance` (§2), the primitive collapse (§5), the reads-throw-on-precondition rule (§7), the property→method switch (§8), and the dropped self-unsubscribe (§9). That would let reviewers separate the uncontroversial ports from the deliberate divergences — which is currently the hardest part of reviewing it.

---

## Appendix A — Confluence comments taken into account

The design decisions on the "Final Assessment" page (`5127372801`, v34) live largely in **inline-comment reply threads**, not the page body, so they are easy to miss. This review took the following into account. Format: *decision/point — author, comment ID (date) — status/how it bears on the review.*

**Decided (and relied on above):**

- **`Instance` name retained** (not `PathInstance` / `LiveObjectInstance`) — thread opened by Sachin `5131894787`, resolved by Sachin `5135695874` (9 Jun): "keep it as `Instance` without changing the naming convention." Proposal complies.
- **`at()` lives on `LiveMapPathObject` only**, not the base — Sachin `5131927555` / `5132156929`, agreed by Lawrence `5132386305` (8 Jun). Proposal complies (§13).
- **`compactJson()` kept un-narrowed in Swift; `id` made non-null on `LiveMapInstance`/`LiveCounter` and removed from base `Instance`** — Lawrence `5135269889` (8 Jun), in the thread opened at `5132386312`. Rationale: Swift's JSON is an enum, so there is no covariant supertype to narrow along; `compactJson` is valued for human-readable output. Basis for §4 (un-narrowed is acceptable, but the base return must be non-optional) and for the `id` placement the proposal gets right. Generalised into RTTS7a ("implementations may choose not to narrow").
- **`subscribe` only on `LiveMap`/`LiveCounter` instances; base `Instance` exposes only `compactJson`** — Sachin `5136908296` / `5135630355` (9 Jun); also RTTS7b. Proposal complies (§9, §13).
- **Type renames** (`LiveMap`→`InternalLiveMap`, `LiveCounter`→`InternalLiveCounter`, `LiveMapValueType`→`LiveMap`, `LiveCounterValueType`→`LiveCounter`) — Sachin `5135794182` → spec PR #489 (9 Jun). Proposal complies (§10).

**Considered but open / unresolved (they inform the recommendations):**

- **A single `type()` / `InstanceType` enum to switch over** (for both `Instance` and `PathObject`), instead of repeated per-type checks — Lawrence `5132582914`; Sachin agreed it is a good alternative (`5131173926` / `5132550163` / `5131698184`) but kept the per-type naming for now. Directly related to `ValueType`/`getType` (§3) and to the Swift `Instance`-enum direction (§2).
- **Whether to drop the inheritance entirely** (both interfaces are small; extract the shared part into a common interface) — Lawrence `5134549008` (8 Jun); never resolved. The deeper question behind §2 and §4.
- **What `LiveCounterPathObject.value()` does when no counter resolves** (throw vs `null`) — footer, Lawrence `5132713985` / `5133402116` (8 Jun); Sachin: ably-js silently ignores, plan to keep. **Subsequently settled by spec #491 RTTS6b: return `null`, do not throw** — so the proposal's `Double?` on the *PathObject* is correct (§7); the comment's "presumably throws" assumption did not carry through.
- **Java's primitive granularity vs a `Primitive` base type** — footer, Lawrence `5132091394`; Sachin `5132451847`: Java uses granular per-primitive types, a base `Primitive` is optional. Confirms the cross-SDK divergence flagged in §5 (Swift collapses to one `Primitive`; Java went granular).

**Raised by the PR author, still unanswered:**

- **"Why is `subscribe` not in base `Instance`?"** — Marat `5184815127` (25 Jun); no reply recorded. Answered in §9 and by RTTS7b: moving it off the base turns the runtime "no subscribe on primitives" error (RTINS16c) into a compile-time guarantee.
