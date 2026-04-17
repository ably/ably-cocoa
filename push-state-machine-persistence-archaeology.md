# Push state machine persistence archaeology

Background research for potential future work on push state machine persistence. This is out of scope for the current investigation but captured here for reference.

## Which states are persistent in each SDK?

| State | ably-cocoa | ably-java | ably-js |
|---|---|---|---|
| `NotActivated` | Persistent | Persistent | Persistent |
| `WaitingForPushDeviceDetails` | Persistent | Persistent | Not persistent |
| `WaitingForDeviceRegistration` | Not persistent | Not persistent | Not persistent |
| `WaitingForNewPushDeviceDetails` | Persistent | Persistent | Persistent |
| `WaitingForRegistrationSync` | Not persistent | Not persistent | Not persistent |
| `AfterRegistrationSyncFailed` | Persistent | Persistent | Not persistent |
| `WaitingForDeregistration` | Not persistent | Not persistent | Not persistent |

ably-js is the most aggressive — it only persists `NotActivated` and `WaitingForNewPushDeviceDetails`.

The spec (RSH3) does not prescribe which states should be persistent. It says "some kind of on-disk storage to which the state machine's state must be persisted" without distinguishing.

## Was the split there from the start?

**ably-cocoa**: Yes. The `ARTPushActivationPersistentState` base class was introduced in the very first push implementation (commit `ce1ce28d`, Feb 2017). The same four persistent / three non-persistent split has been there from the beginning.

**ably-java**: Yes. The `PersistentState` abstract class was present from the initial push activation state machine implementation (commit `1f88b8b4`, Dec 2018, by Paddy Byers). Same split as ably-cocoa.

**ably-js**: Yes. The `isPersistentState()` function was introduced in the initial push activation plugin (commit `24893a9f`, May 2024, by Owen Pearson, merged in PR #1775). However, ably-js made a different choice about which states to persist — only `NotActivated` and `WaitingForNewPushDeviceDetails`.

## What's the motivation for non-persistent states?

The non-persistent states (`WaitingForDeviceRegistration`, `WaitingForRegistrationSync`, `WaitingForDeregistration`) all represent "waiting for an HTTP response." If the app is killed, the response is never coming.

The intent is to revert to the previous stable state and re-trigger the operation on restart. This is described in [ably-java#546](https://github.com/ably/ably-java/issues/546), which is referenced by [ably-cocoa#966](https://github.com/ably/ably-cocoa/issues/966).

Additionally, in ably-java, there's a practical serialisation reason: events with constructor parameters (like `GettingDeviceRegistrationFailed` which carries an error) can't be reconstructed from a persisted string name. Events and states that carry data are not persisted (see ably-java `EventTest.java` lines 45-52).

## The ably-cocoa#966 problem

The flaw in the non-persistent approach: reverting to the previous state doesn't always re-trigger the operation. For example, if the state was `WaitingForPushDeviceDetails` (persistent) and `GotPushDeviceDetails` triggered a POST, the state moves to `WaitingForDeviceRegistration` (not persistent). If the app is killed, the state reverts to `WaitingForPushDeviceDetails`. But the APNS token is already persisted, so the SDK doesn't re-emit `GotPushDeviceDetails` (it thinks the token hasn't changed), and the state machine gets stuck.

ably-cocoa has a workaround for this specific case in `ARTPushActivationStateMachine.m` (lines 70-76): on init, if the state is `WaitingForPushDeviceDetails` and the device already has an APNS token, it re-emits `GotPushDeviceDetails`.

ably-js doesn't appear to have any special handling for this case. Since it only persists `NotActivated` and `WaitingForNewPushDeviceDetails`, any interruption during the registration flow reverts to `NotActivated` and the user needs to call `activate()` again.

## The attempt to make WaitingForDeviceRegistration persistent (ably-cocoa)

**Commit `0e921865`** (Sep 24, 2021, by Marat Al) on branch `fix/966-non-persistent-state` changed `WaitingForDeviceRegistration` to persistent and added logic to re-submit the device registration request when the state machine starts up in this state.

This branch was **never merged to main**. It appears to have been an experimental attempt to properly fix #966 by making the "waiting" state persistent and re-submitting the in-flight request on restart.

A later branch (`min-ios14-swift-mig`, commit `5708d9a8`, Aug 2024, by Umair Hussain) also touched this but as part of a broader Swift migration refactor. That branch was also **never merged to main**.

So the current state on main is that `WaitingForDeviceRegistration` remains non-persistent, and the #966 workaround (re-emitting `GotPushDeviceDetails` on init) is still in place.

## How ably-js handles things differently

ably-js only persists two states, making a simpler but less resilient choice. It doesn't attempt to recover from interrupted operations — if the app is killed during registration, it reverts to `NotActivated` and the user must call `activate()` again. This avoids the #966 class of bugs entirely (no stuck states) at the cost of occasionally requiring re-registration.

## Repos examined

| Repo | HEAD at time of examination |
|---|---|
| ably-cocoa | `745e7b7a` |
| ably-java | `da4c60f0` |
| ably-js | `17be43e1` |
