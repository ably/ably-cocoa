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

## Proposed spec changes

We are drafting spec changes (on the `2026-03-20-investigating-ably-cocoa-push-registration-failures` branch of the specification repo) that address the issues above. The key changes are:

- **RSH3h**: Require the state machine to load and verify `LocalDevice` details at init time, before processing any events. If the load fails, discard everything and start in `NotActivated`.
- **RSH8a2**: Require the (`id`, `deviceSecret`, `deviceIdentityToken`) tuple to be persisted and loaded atomically. If an implementation splits storage (e.g. Keychain for secrets), it must provide a mechanism to detect when the loaded tuple doesn't match what was persisted.
- **RSH8a2a**: For legacy data without an atomicity mechanism, check invariants (id and secret both present or both absent, token only if id and secret present).
- **RSH3i** (`ValidatingRegistration` state): For legacy data that passes the invariant check but can't be locally verified (all three fields present but token may belong to a different id), validate against the server before accepting the data.

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

### Current recommendation

Option 1 is the simplest and safest. The trade-off (orphaning a registration when the token is stale) is acceptable because:
- This is exactly what's already happening today with the bug
- The orphaned registration is already useless (the client can't authenticate against it)
- It only happens once per device during migration from legacy data
- The user re-registers cleanly on the next `activate()`
