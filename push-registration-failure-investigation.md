# Push registration failure investigation

2026-03-20

## Customer report

A customer using ably-cocoa 1.2.35 on iOS reported:

- Error when subscribing to a channel: "Token deviceId does not match requested device operation" (error code 40100)
- Multiple active device push registrations for the same user/device in the Ably dashboard
- Three device registrations with different UUIDs but the same `clientId`, two sharing identical APNS tokens

## What the server error means

The error is raised by the realtime server when a request to `/push/deviceRegistrations/:deviceId` includes a device identity token whose embedded `deviceId` doesn't match the `:deviceId` in the URL path. It's a security check: a device token should only authorise operations on the device it was issued for.

## Root cause

The device ID and device identity token can get out of sync because they are stored in different places with different availability characteristics:

| Field | Storage | Availability |
|---|---|---|
| Device ID | `NSUserDefaults` | Always |
| Device identity token | `NSUserDefaults` | Always |
| Device secret | Keychain (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`) | Not until first unlock after reboot |

When the app launches in the background before the user has unlocked the device after a reboot (e.g. woken by a push notification), the Keychain is inaccessible. The device loading code in `ARTLocalDevice.m` (`deviceWithStorage:logger:`) then:

1. Loads `deviceId` from `NSUserDefaults` — succeeds
2. Loads `deviceSecret` from Keychain — fails (`errSecInteractionNotAllowed`), returns nil
3. Since `deviceSecret` is nil, generates a **new** device ID and secret pair (`generateAndPersistPairOfDeviceIdAndSecret`)
4. Loads the **old** identity token from `NSUserDefaults` — it's still there, tied to the old device ID

The device is now in an inconsistent state: new ID, new secret, old identity token. When the activation state machine tries to sync or update the registration, it sends a request with the new device ID in the URL but authenticates with the old identity token (which contains the old device ID embedded in it). The server rejects this with error 40100.

Each time this happens, it can also create a new orphaned registration on the server, explaining the multiple registrations the customer sees.

### Full inventory of persisted data in ably-cocoa

This is a comprehensive list of everything ably-cocoa persists. All persistence goes through `ARTLocalDeviceStorage`, which provides two storage mechanisms: `objectForKey:`/`setObject:forKey:` (backed by NSUserDefaults) and `secretForDevice:`/`setSecret:forDevice:` (backed by the Keychain, keyed by device ID). Everything persisted is push-related:

| Key | Storage | What it is | Consequence of loss |
|---|---|---|---|
| `ARTDeviceId` | NSUserDefaults | Device UUID | If lost without also losing the secret and token, causes the mismatch bug. If lost alongside everything else, device re-registers on next `activate()`. |
| `ARTDeviceSecret` | Keychain (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`), keyed by device ID | Device secret for authenticating push operations | Unavailable before first unlock. Loss triggers id/secret regeneration in current code, which is the root cause of this bug. |
| `ARTDeviceIdentityToken` | NSUserDefaults | Token returned by server after registration, used for authenticating push operations | Stored under a fixed key (not keyed by device ID), so survives id regeneration — this is the stale-token problem. If lost on its own, the device would need to re-register to get a new one. |
| `ARTClientId` | NSUserDefaults | Client identity associated with the device | If lost, falls back to the identity token's client ID (existing code at `ARTLocalDevice.m:90-93`). Low severity. |
| `ARTAPNSDeviceToken-default` | NSUserDefaults | APNS device token (default) | Recoverable from the platform — iOS provides a new one via `registerForRemoteNotifications`. Loss triggers a `GotPushDeviceDetails` event and a PATCH to update the server. Note: Apple's guidance is to ["never cache device tokens in local storage"](https://developer.apple.com/documentation/usernotifications/registering_your_app_with_apns), but this is better interpreted as "don't trust cached tokens without re-validating" — RSH8i requires validation against the platform on each launch. See [specification#25](https://github.com/ably/specification/issues/25). |
| `ARTAPNSDeviceToken-location` | NSUserDefaults | APNS device token (location) | Same as above. |
| `ARTPushActivationCurrentState` | NSUserDefaults | Persisted state machine state (archived object) | Defaults to `NotActivated` if lost. Device re-syncs or re-registers on next `activate()`. Causes unnecessary REST calls but is self-correcting. |
| `ARTPushActivationPendingEvents` | NSUserDefaults | Queued state machine events (archived array) | Defaults to empty array if lost. Pending events are dropped — may cause missed transitions but state machine recovers on next `activate()`. |

**Storage mechanisms and their failure modes:**

- **NSUserDefaults**: Backed by a plist file. Availability depends on the app's data protection class — the default is `NSFileProtectionCompleteUntilFirstUserAuthentication`, which has a similar availability window to the Keychain's `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`. Can also fail due to plist corruption. In practice, much more reliable than the Keychain, but not guaranteed always-available.
- **Keychain** (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`): Not available until the user unlocks the device after a reboot. This is the primary cause of the bug. Read failures return nil without distinguishing "not found" from "inaccessible." Write failures are also possible when inaccessible.
- **`NSFileProtectionNone`** (proposed): Always available, no encryption at rest. Would eliminate the availability issue entirely but stores secrets in plain text on disk.

### Historical context

The Keychain accessibility attribute was changed from `kSecAttrAccessibleAlwaysThisDeviceOnly` (always available, but deprecated since iOS 12) to `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` in commit `a9e4b24` (Aug 2021). This was labelled "Catalyst kSecAttr warning fix" — it fixed a deprecation warning but introduced the before-first-unlock failure window.

## Existing issues

- [#1109 — "Push: new device secret created for preexisting ID"](https://github.com/ably/ably-cocoa/issues/1109) (March 2021) — the original report of this class of problem. PR [#1187](https://github.com/ably/ably-cocoa/pull/1187) (merged Oct 2021) partially fixed it by ensuring the secret is only regenerated alongside the device ID. But the root cause (Keychain inaccessibility, and the identity token not being cleared) was not addressed.
- [#1257 — "Respect RSH8j"](https://github.com/ably/ably-cocoa/issues/1257) (Dec 2021) — filed after investigating the above. Notes that when the ID is regenerated, the identity token may no longer match, and the state machine should transition to `NotActivated`. A WIP branch `RSH8j-transition-to-NotActivated-after-failing-to-load-LocalDevice` exists with commits from Jan–Feb 2022 but was never completed.
- [#1256 — "Respecting RSH8b"](https://github.com/ably/ably-cocoa/issues/1256) (Dec 2021) — about generating ID/secret lazily on activation rather than eagerly at device fetch time, per the spec. Would require making `id` nullable (breaking change).
- [#966 — "Non-persistent push state machine states conflict with RSH3"](https://github.com/ably/ably-cocoa/issues/966) (Jan 2020) — related issue about non-persistent state machine states.

## Specification analysis

The relevant spec point is RSH8j (now moved to RSH8a1 as part of this investigation):

> If the `LocalDevice` `id` or `deviceSecret` attributes are not able to be loaded then those LocalDevice details must be discarded and the ActivationStateMachine machine should transition to the `NotActivated` state.

### Problems with the spec as written

1. **RSH8a1 doesn't say to clear the identity token.** "Those LocalDevice details" refers to `id` and `deviceSecret` only. But if the identity token survives, the `NotActivated` + `CalledActivate` path hits RSH3a2a (which checks for an existing identity token) before RSH3a2b (which would generate new credentials). So RSH3a2a tries to sync using the stale identity token with the new device ID, which fails.

2. **RSH8a1 directly mutates the state machine state.** Every other RSH8 point that interacts with the state machine does so by sending events. RSH8a1 is the only one that bypasses the event-driven model and sets the state directly. This is a breakage of the state machine abstraction.

3. **RSH8a1 doesn't distinguish between load contexts.** RSH8a says the `LocalDevice` is initialised "when first required, either as a result of a call to `RestClient#device` or `RealtimeClient#device`, or as a result of an operation involving the Activation State Machine." If the load failure happens during an explicit `client.device` fetch, a side-effect transition to `NotActivated` is reasonable. If it happens during state machine event handling, silently resetting the state from underneath the event handler is problematic.

4. **Multiple spec points overlap in describing when id/deviceSecret are generated.** RSH8a (loading), RSH8b (generation, delegating to RSH3a2b), RSH8a1 (load failure), and RSH3a2b itself all touch on the same lifecycle. The RSH8k2 note acknowledges that implementations don't even agree on whether generation is eager or lazy.

### How the three SDKs differ

| Behaviour | ably-cocoa | ably-js | ably-java |
|---|---|---|---|
| id/secret generation | Eager (at device fetch) | Eager (at device fetch) | Lazy (on `CalledActivate`, per RSH3a2b) |
| RSH8a1 implementation | Regenerates id/secret but doesn't clear identity token or reset state machine | No implementation; assumes if id loads, secret loads too | No implementation observed |
| Storage for secret | Keychain (different availability from id) | Same storage as id | Same storage as id (`SharedPreferences`) |

## Spec assumptions about storage

There are two things to note about how the spec relates to storage:

**The spec assumes LocalDevice is a single atomic blob.** It doesn't anticipate implementations splitting storage across mechanisms with different availability characteristics. ably-cocoa does this (Keychain for secret, NSUserDefaults for everything else), and this is the root cause of the bug. Our proposed RSH8a2 would acknowledge that implementations may split storage and define the atomicity requirement, plus RSH8a2a for ably-cocoa's specific legacy situation. However, we have not yet proposed a concrete mechanism for how ably-cocoa would achieve atomicity going forward — that is the "move to always-available storage" work described in the "Storage availability" section below.

**The spec's failure recovery (RSH3h1) is a safety net, not a routine code path.** RSH3h1 handles load failures by discarding everything and starting in `NotActivated`. This works correctly in isolation, but the consequences of it firing routinely are not addressed: orphaned registrations accumulate on the server, push channel subscriptions are lost, and there is no mechanism for cleaning up. Paddy's [comment on #1109](https://github.com/ably/ably-cocoa/issues/1109#issuecomment-934163390) — "we need to use a persistence mechanism for the device registration and secret that is always available" — suggests this was never intended to be a routine occurrence. If ably-cocoa ships the spec changes without also fixing the storage to be always-available, the recovery behaviour would be correct but would fire too frequently, with accumulating side effects.

### What should be stored atomically?

The proposed RSH8a2 specifies atomicity for the (`id`, `deviceSecret`, `deviceIdentityToken`) tuple. But it's worth considering whether the spec's model actually implies a larger atomic unit.

The state machine state carries assumptions about which LocalDevice properties exist — e.g. `WaitingForNewPushDeviceDetails` assumes id, secret, and token are all present. Our proposed RSH3h says "the persisted activation state is only valid if the LocalDevice details it depends on are available." This means the state machine state and the LocalDevice data are logically one unit: if one changes without the other, the assumptions are violated.

Looking at the full set of persisted items:

- **(`id`, `deviceSecret`, `deviceIdentityToken`)**: critical. Out-of-sync state causes the 40100 error and the broken error loop that prompted this investigation. RSH8a2 proposes atomicity for this tuple.
- **`clientId`**: has a fallback (loaded from the identity token if missing, `ARTLocalDevice.m:90-93`). If out of sync with the rest, the worst case is RSH3a2a1 detecting a mismatch and firing `SyncRegistrationFailed` with error 61002, which the state machine handles.
- **APNS tokens**: issued by Apple for the physical device, not tied to the Ably device id. Always valid for the physical device regardless of which Ably device id is in use. Re-validated against the platform on each launch (RSH8i). Can't meaningfully be "out of sync" with the device id.
- **State machine state and pending events**: if lost, defaults to `NotActivated` with an empty queue. Self-corrects on next `activate()` — causes an unnecessary re-sync or re-registration but not a broken state.

So the (`id`, `deviceSecret`, `deviceIdentityToken`) tuple is the only group where atomicity is critical for correctness. The other items either self-correct or have fallbacks. However, the state machine state is logically part of the same unit — it just happens that losing it is recoverable.

In ably-java and ably-js, everything is stored in the same mechanism (SharedPreferences / localStorage), so atomicity is effectively achieved by accident. If ably-cocoa is redesigning its storage, it may be simplest to store the entire set as one blob rather than reasoning about which subsets need atomicity. This would also avoid future bugs if new persisted fields are added that have dependencies we haven't anticipated.

## Proposed spec changes

We are drafting spec changes (on the `2026-03-20-investigating-ably-cocoa-push-registration-failures` branch of the specification repo) that address the issues above. The key changes are:

- **RSH3h**: Require the state machine to load and verify `LocalDevice` details at init time, before processing any events. If the load fails, discard everything and start in `NotActivated`.
- **RSH8a2**: Require the (`id`, `deviceSecret`, `deviceIdentityToken`) tuple to be persisted and loaded atomically. If an implementation splits storage (e.g. Keychain for secrets), it must provide a mechanism to detect when the loaded tuple doesn't match what was persisted.
- **RSH8a2a**: For legacy data without an atomicity mechanism, check invariants (id and secret both present or both absent, token only if id and secret present).
- **RSH3i** (`ValidatingRegistration` state): For legacy data that passes the invariant check but can't be locally verified (all three fields present but token may belong to a different id), validate against the server before accepting the data.

### Understanding RSH3a2a — the existing "validation" mechanism

RSH3a2a fires in `NotActivated` when `CalledActivate` is received and the device has a `deviceIdentityToken`. It does a PUT to `/push/deviceRegistrations/:deviceId` with the full device details, authenticating with the token. The spec describes this as "performs a validation of the local DeviceDetails." If the PUT succeeds (`RegistrationSynced`), the device is confirmed as registered. If it fails (`SyncRegistrationFailed`), the state machine goes to `AfterRegistrationSyncFailed`.

**What is it actually validating?** Not the token specifically — it's syncing the device's current state with the server ("am I still registered, and here are my current details"). The token is just the authentication mechanism for this sync. The token's validity is tested as a side effect of authenticating the request.

**When would you be in `NotActivated` with a token?** We traced all the paths into `NotActivated`:
- RSH3g2c (after deregistration): RSH3g2a clears all device details including the token
- RSH3b2b (`CalledDeactivate` in `WaitingForPushDeviceDetails`): no token at this stage
- RSH3b4b (`GettingPushDeviceDetailsFailed`): no token at this stage
- RSH3c3b (`GettingDeviceRegistrationFailed`): no token at this stage

None of these paths leave a token in place. So RSH3a2a doesn't appear to be reachable through normal state machine transitions. It seems to exist only for the case where the persisted state is `NotActivated` but the device data (including a token) somehow survived — exactly the kind of state/data inconsistency our RSH3h is designed to catch. It's a pre-existing attempt to handle this edge case, but without an explicit acknowledgement of why you'd be in that state.

**Could we hook into it for our recovery?** If we kept the token and started in `NotActivated`, RSH3a2a would fire automatically on the next `CalledActivate`. If the token is valid, the PUT succeeds and we're done — the existing mechanism handles it. The problem is when the token is invalid: the PUT fails with 401, `SyncRegistrationFailed` fires, the state goes to `AfterRegistrationSyncFailed`, and from there the next `CalledActivate` does the same as RSH3a2a again (RSH3f1a) (RSH3f1a) — the same loop we identified at the start of this investigation. RSH3a2a's failure path has no special handling for 401; it just loops.

A possible approach: modify `AfterRegistrationSyncFailed` (or `WaitingForRegistrationSync`) to detect that the sync failed with a 401, discard the token, and fall through to RSH3a2b onwards (fresh registration with existing id/secret). This would fix the loop for all cases — not just legacy migration — meaning any device that ends up with a mismatched token would self-recover through the existing state machine. However, this would be a change to the general sync failure handling, not scoped to the legacy migration case. We have not yet explored this option in the spec changes.

### The legacy validation problem

In ably-cocoa, the `deviceSecret` is stored in the Keychain keyed by device ID, so if we can load a secret for a given id, we know they match. The `deviceIdentityToken` is stored in `NSUserDefaults` under a fixed key, not keyed by device id. So we can have all three fields present and loadable, but the token may have been issued for a previous device id that was since overwritten.

We know the secret is correct for the current device id because it is stored in the Keychain keyed by device id — if we load a secret for id=C, it must be the secret that was generated alongside id=C. The token, by contrast, is stored in `NSUserDefaults` under a fixed key (`ARTDeviceIdentityToken`), not keyed by device id. It is also opaque to the client — we cannot inspect it to see which device id it was issued for. So while we can trust the (id, secret) binding locally, we cannot verify the (id, token) binding without a server round-trip.

This is a narrow case: legacy data, no atomicity mechanism, all three fields present and loadable, but we can't locally verify the token belongs to the current id. Once the atomicity mechanism (RSH8a2) is in place, this state is never entered again.

### Options for the server validation (RSH3i)

**Option 1: Validate the token with a non-mutating GET.** Make a GET request to `/push/deviceRegistrations/:deviceId` authenticated with the `X-Ably-DeviceToken` header. If it succeeds (200), the token matches the device id and the tuple is consistent — persist with the atomicity mechanism and proceed. If it fails (40100), the token is stale — discard everything and transition to `NotActivated`. On the next `activate()`, the device goes through the clean registration path with a new id and secret.

- Pros: simple, non-mutating, doesn't need the custom `registerCallback`
- Cons: if the token is stale, we discard the (id, secret) pair even though they may be valid on the server — this orphans the server-side registration and forces a full re-registration

**Option 2: Recreate the token using the secret.** Make a PATCH request to `/push/deviceRegistrations/:deviceId` authenticated with the `X-Ably-DeviceSecret` header. The server validates the (id, secret) pair, and the response includes a fresh `deviceIdentityToken`. If it succeeds, persist the fresh tuple with the atomicity mechanism and proceed. If it fails, the (id, secret) pair isn't registered — discard everything and transition to `NotActivated`.

- Pros: preserves the existing registration if the (id, secret) is valid; no orphaned registrations
- Cons: mutating (though in practice a PATCH with no body changes nothing); the spec provides a custom `registerCallback` that users can substitute for registration HTTP calls, but the callback has no way to distinguish between the different types of registration request (POST/PUT/PATCH) — it's unclear whether calling it here would do the right thing, and we'd need to decide whether to use it or bypass it

**Option 3: Use the secret for all subsequent authentication and abandon the token.** Instead of validating or recreating the token, just use the device secret for all requests.

- Pros: simple, no server round-trip needed
- Cons: unknown consequences — the token exists for a reason (the spec calls it `deviceIdentityToken` / docs call it `updateToken`); unclear what functionality would be lost by not having it; would diverge from the spec's authentication model

### How much do we care about preserving the registration?

A device that reaches the legacy validation path (RSH8a2a2) has legacy data without an atomicity mechanism, all three fields present, but a token that may belong to a different device id. There are two scenarios: either the token is actually valid (the device was never affected by the Keychain bug — e.g. it was never launched in the background before first unlock), or the token is stale (the device has been through one or more cycles of id/secret regeneration). In the latter case, the server may already have multiple orphaned registrations, and the cost of one more is low. In the former case, the registration is still valid and preserving it would avoid an unnecessary re-registration.

Both directions below preserve the device id (and any push channel subscriptions tied to it), since on rejection both end up in the same normal registration flow (RSH3a2b onwards). The `registerCallback` is already used for POST, PUT, and PATCH cases without distinction (RSH3b3a, RSH3d3a, RSH3a2a2), so it works in both directions too.

### Direction A: Validate the token, then re-register if invalid

This is option 1 above, implemented as two new state machine states:
- `ValidatingDeviceIdentityToken` (RSH3i): on `CalledActivate`, makes a non-mutating GET to check the token
- `WaitingForDeviceIdentityTokenValidation` (RSH3j): handles the result — if valid, persist with atomicity; if rejected (401), discard token and re-register via RSH3a2b onwards; if other error, report and let the user retry

This is currently written into the spec on the `2026-03-20-investigating-ably-cocoa-push-registration-failures` branch (commits `faa0fb8` through `25e0fd6`).

The spec currently discards all `LocalDevice` details on rejection and re-registers fresh (RSH3j2a/RSH3j2b). There is a TODO in RSH3j2a to investigate whether it's possible instead to preserve the (id, secret) pair and regenerate only the token, since the secret is known to be valid for the current id. One possible approach: use a PATCH authenticated with `X-Ably-DeviceSecret` (like RSH3d3b), which the server accepts (confirmed in `rest_push.ts:322-324`) and which returns a fresh `deviceIdentityToken` (confirmed in `rest_push.ts:1814-1825`). This would preserve the existing registration. If the PATCH fails (e.g. device not registered), fall back to fresh registration. Having a dedicated state makes this kind of special-casing possible, whereas direction B would need to rely on the POST's undocumented upsert behaviour.

Pros:
- Only re-registers when the token is actually invalid
- Clear separation of validation and registration
- The dedicated state provides a path to preserve the registration via PATCH in the future (see TODO in RSH3j2a)

Cons:
- Adds two new states and three new events for a one-time migration path

### Direction B: Skip validation, just re-register

Not yet written into the spec.

Instead of validating the token against the server, simply discard it and start in `NotActivated`. On the next `CalledActivate`:
1. RSH3a2a doesn't apply (no token)
2. RSH3a2b: device already has id/secret → skip generation
3. RSH3a2c onwards: normal registration flow
4. RSH3b3b: POST to `/push/deviceRegistrations` — the server treats this as an upsert (confirmed by reading the realtime server code: `upsertDeviceRegistration` at `rest_push.ts:1768` handles both new and existing registrations via `postDeviceRegistration`)
5. Server returns a fresh `deviceIdentityToken`

Pros:
- No new states or events — the existing state machine handles everything

Cons:
- Every device upgrading from legacy data makes a POST on first activation, even if the token was actually valid (one-time cost)
- Relies on the server treating POST as an upsert, which is current behaviour but not explicitly part of the spec

### Direction C: Hook into the existing RSH3a2a validation mechanism

Not yet written into the spec.

In the RSH8a2a2 case (legacy data, all three present, no atomicity), instead of discarding the token, keep it and start in `NotActivated`. On `CalledActivate`, RSH3a2a fires automatically — it does a PUT to sync the device details with the server, authenticating with the token. If the token is valid, the PUT succeeds and we're done with no additional mechanism needed.

The problem is the failure path: if the token is invalid (401), RSH3a2a fires `SyncRegistrationFailed`, which leads to `AfterRegistrationSyncFailed`, which on the next `CalledActivate` does the same as RSH3a2a again (RSH3f1a) — the same loop we identified at the start. To make this work, we'd need to modify the sync failure handling: if the sync fails with a 401, discard the token and fall through to RSH3a2b onwards (fresh registration with existing id/secret).

This change would not be scoped to the legacy migration case — it would fix the loop for *all* cases where a device ends up with a mismatched token, making it a general improvement to the state machine's resilience. However, it requires a better understanding of what RSH3a2a is for and whether modifying its failure path would have unintended consequences (see "Understanding RSH3a2a" above).

Pros:
- No new states or events for the migration case — uses the existing validation mechanism
- Fixes the token-mismatch loop for all cases, not just legacy migration
- If the token is valid, no unnecessary re-registration or server round-trip beyond what RSH3a2a already does

Cons:
- Requires modifying the general sync failure handling (AfterRegistrationSyncFailed / WaitingForRegistrationSync), which affects all devices, not just those migrating from legacy data
- RSH3a2a's purpose and reachability are not fully understood (see above) — we need more clarity before changing its failure path
- By the time we're in `AfterRegistrationSyncFailed` with a 401, the context of why we got here is lost. We can't distinguish "401 because we kept a stale token during legacy migration" from some other 401 during a sync. This means we can't produce a helpful log message about legacy recovery, and if there's a case where discarding the token on 401 is the wrong response, we've applied it too broadly.

### Current recommendation

We have not yet reached a decision. Direction A is fully specced and works but adds complexity for a one-time migration. Direction B is simpler but relies on undocumented server behaviour. Direction C is the most elegant and fixes the problem generally, but requires more investigation into RSH3a2a and the consequences of modifying the sync failure path.

## Storage availability

The spec changes above address the immediate problem (detecting and recovering from inconsistent data), but there is a deeper issue: the Keychain can be temporarily unavailable (before first unlock after reboot), and even NSUserDefaults availability depends on the app's data protection class (the default is `NSFileProtectionCompleteUntilFirstUserAuthentication`, which has the same availability window as the Keychain's `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`). The only guaranteed-always-available storage on iOS is a file with `NSFileProtectionNone`, which provides no encryption at rest.

This means even with our spec changes, if the app launches before first unlock, the SDK could end up in a regeneration loop: RSH3h1 discards and resets to `NotActivated`, `activate()` generates new id/secret, the write fails because storage is unavailable, next launch discards again, and so on until the user unlocks.

### Proposed approach for ably-cocoa

**Default storage: always-available, no encryption.** Store the (`id`, `deviceSecret`, `deviceIdentityToken`) tuple in a file with `NSFileProtectionNone` (or equivalent always-available mechanism). This means:
- `client.device` works synchronously as it does today
- `activate()` works immediately regardless of device lock state
- No availability issues, no regeneration loop
- This is what ably-java and ably-js effectively do today (SharedPreferences / localStorage)

The trade-off is that the device secret is stored unencrypted on disk. The blast radius of a compromised device secret is limited to push operations for that specific device (updating/deleting the registration, subscribing to push channels). It does not grant access to the Ably API key or to publish/subscribe on channels. On a jailbroken/rooted device where the secret could be extracted, the attacker likely has access to far more than just the device secret.

**Pluggable secure storage (optional).** For customers who require encrypted credential storage (e.g. due to regulatory requirements, as raised in [ably-java#593](https://github.com/ably/ably-java/issues/593)), provide a pluggable storage interface. The user supplies their own storage implementation (e.g. backed by the Keychain) which:
- Exposes an async loading API that can indicate "not yet available"
- Provides a mechanism for subscribing to availability events (on iOS, this maps to `UIApplication.isProtectedDataAvailable` and `UIProtectedDataDidBecomeAvailable`)

If secure storage is used, `client.device` would need a new async variant, and the state machine (RSH3h) would defer loading rather than discarding when storage is temporarily unavailable. This is a larger piece of work and can be done separately from the immediate fix.

### Migrating existing data

The migration from Keychain to always-available storage is closely related to the RSH8a2a legacy data handling:

1. On first launch with the new SDK, check the new always-available storage — empty (nothing migrated yet).
2. Fall back to loading from old locations (NSUserDefaults for id/token, Keychain for secret).
3. If everything loads successfully, write to the new storage with the atomicity mechanism (RSH8a2), then proceed normally. Subsequent launches use the new storage and this migration code never runs again.
4. If the load is partial (e.g. Keychain unavailable before first unlock), the RSH8a2a invariant check catches it (id present, secret absent → violation → RSH3h1 → discard → `NotActivated`).
5. If all three load but the token might be stale, RSH8a2a2 triggers the `ValidatingDeviceIdentityToken` flow (RSH3i).

The problem case is: the user upgrades the app, and the first launch with the new SDK happens before first unlock. The Keychain is unavailable, so the old secret can't be read, so migration can't complete. The device loses its existing push registration and has to re-activate after unlock.

We considered alternatives to avoid this:

1. **Wait for the Keychain to become available before migrating.** This avoids losing the registration, but `client.device` can't return a complete device until migration is done — there's no way to satisfy the non-nullable `id` contract while waiting. Building an async mechanism just for a one-time migration is disproportionate.

2. **Store a "migration pending" flag and keep trying on each launch.** Don't discard anything until migration succeeds; don't process events until then. Similar problem: `client.device` can't return a complete device during the pending period.

Both alternatives run into the same fundamental issue: if the data isn't available yet, `client.device` can't work synchronously. This is the same problem that the pluggable secure storage would face, and solving it requires a larger change (async device loading) that is out of scope for the immediate fix.

Accepting the one-time sacrifice is pragmatic:
- It only affects users who upgrade the app AND whose first launch with the new SDK is before first unlock — a narrow window.
- The outcome (losing the registration, re-registering on next `activate()`) is the same as what's already happening today with the bug, except today it loops indefinitely rather than recovering cleanly.
- After migration (successful or not), the new always-available storage prevents this class of problem from recurring.

### Impact on the spec

The spec changes we've drafted (RSH3h, RSH8a2, etc.) are compatible with both approaches. RSH8a2 says the tuple must be persisted and loaded atomically but doesn't prescribe a storage mechanism. The choice between always-available storage and pluggable secure storage is an implementation decision for each SDK. A future spec enhancement could add guidance for the "wait for availability" pattern if multiple SDKs need it.

### Recommended order of work

Steps 1 and 2 are intertwined and should be treated as a single piece of work. The new storage (step 1) needs the migration and integrity checking logic (step 2), because migrating from old storage is where the RSH8a2a invariant checks and RSH3i token validation are needed. And the spec changes (step 2) rely on always-available storage (step 1) to avoid the regeneration loop where the SDK repeatedly discards and regenerates credentials because the Keychain is inaccessible.

1. **Move to always-available storage + implement the spec changes** — store the (`id`, `deviceSecret`, `deviceIdentityToken`) tuple in a file with `NSFileProtectionNone` (or equivalent), with the RSH8a2 atomicity mechanism. Implement RSH3h (load and verify at state machine init), RSH8a2a (legacy data invariant checks and token validation), and RSH3i (`ValidatingDeviceIdentityToken` state). This fixes the root cause and handles migration from old Keychain/NSUserDefaults storage in one release.
2. **Pluggable secure storage** — future enhancement for customers who require encrypted credential storage, with async device loading. Separate piece of work.

### Privacy manifest

The current privacy manifest (`Source/PrivacyInfo.xcprivacy`) declares:
- `NSPrivacyCollectedDataTypeDeviceID` (linked, tracking, for app functionality)
- `NSPrivacyAccessedAPICategoryUserDefaults` with reason `CA92.1`

If we move to a custom file with `NSFileProtectionNone`, the UserDefaults declaration is still needed (for other data and during migration). Custom file I/O does not fall under Apple's "required reason APIs", so no additional privacy manifest declarations are needed for the new storage mechanism.

### Customer expectations around Keychain storage

Keychain storage of the device secret is not documented anywhere as a feature or guarantee — it is not mentioned in the README, public headers, or any public documentation. The only references are in the CHANGELOG as internal implementation changes (removing the SAMKeychain dependency, replacing `SecKeychainItemDelete`).

No customer should reasonably be depending on the device secret being stored in the Keychain. The change should be mentioned in release notes for transparency, but it does not constitute a breaking change in any documented sense.

For customers who do require encrypted credential storage (as raised in [ably-java#593](https://github.com/ably/ably-java/issues/593)), the pluggable secure storage (step 2 above) would provide an explicit, supported mechanism for this — rather than the current situation where it's an undocumented implementation detail.
