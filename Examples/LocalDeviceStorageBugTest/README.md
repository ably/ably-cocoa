# LocalDeviceStorageBugTest

A minimal iOS app for investigating push registration failures in ably-cocoa.

## How it works

The app creates two Ably client instances:

- **`mainAbly`** (`ARTRealtime`) — the client under test. Its `clientId` is set to `appInstallation-<appInstallationID>` so that multiple device registrations from the same installation are easy to identify in the Ably dashboard — this is the failure mode under investigation (device ID gets unnecessarily recreated).
- **`eventLoggingAbly`** (`ARTRealtime`) — used solely to log events emitted by the app, by publishing them to the `LocalDeviceStorageBugTest-events` channel. Uses a Realtime connection to preserve message ordering.

### VoIP push

The app registers for VoIP pushes via PushKit. This gives us a way to deterministically launch the app before first unlock, which is important for reproducing the bug under investigation. A minimal CallKit handler is included to satisfy the iOS requirement that VoIP pushes must report an incoming call.

### UI actions

The app provides two buttons:

- **Activate Push** — calls `push.activate()` on `mainAbly`, registering the device with Ably for push notifications.
- **Subscribe to Push Channel** — subscribes the device to push notifications on the `push-test` channel.

Each shows its result (success or error) in the UI.

### Settings

A settings section provides toggles to automatically perform these actions on app launch:

- **Auto-activate push on launch**
- **Auto-subscribe to push channel on launch**

When both are enabled, the app activates first and then subscribes after activation succeeds. Settings are stored in a JSON file with `FileProtectionType.none`, so they are readable even when the device is locked (before first unlock). This is important because the app can be launched by a VoIP push before the user has unlocked the device.

### Events

All events published to the channel are defined by the `Event` enum in `Event.swift`. Every event payload includes:

- **`appInstallationID`** — a UUID generated on first launch and persisted in an unprotected file. Stable across launches but reset on reinstallation.
- **`appLaunchID`** — a UUID generated fresh each launch.

Current events:

- **`appLaunched`** — published before any other event. Includes `protectedDataAvailable` indicating whether the device was unlocked at launch time.
- **`ablyLog`** — a log message from the SDK (level and message text), captured via a custom `ARTLog` handler on `mainAbly`.
- **`voipTokenUpdated`** — PushKit provided a new VoIP device token.
- **`voipPushReceived`** — a VoIP push notification was received.
- **`voipTokenInvalidated`** — PushKit invalidated the VoIP device token.
- **`pushActivateAttempt`** / **`pushActivateResult`** — a call to `push.activate()` and its outcome. Linked by an attempt ID. The result includes a snapshot of the `ARTLocalDevice`, so that changes to device details (e.g. ID, secret) can be detected — this is useful for identifying cases where the SDK was unable to load persisted data (e.g. when launched before first unlock).
- **`pushSubscribeAttempt`** / **`pushSubscribeResult`** — a call to `push.subscribeDevice` and its outcome. Linked by an attempt ID.
- **`protectedDataAvailability`** — published when protected data availability changes after launch (device locked/unlocked).

Attempt events include a `reason` (`userTappedButton` or `appLaunch`). Result events include the full `ARTErrorInfo` on failure.

## Setup

1. Copy `Secrets.example.swift` to `LocalDeviceStorageBugTest/Secrets.swift` and insert your Ably API key. (`Secrets.swift` is gitignored.)
2. Enable message persistence on the events channel so that `send-voip-push.sh` (and anything else reading history) can find events beyond the default 2-minute retention:
   ```sh
   ably apps channel-rules create --name "LocalDeviceStorageBugTest-events" --persisted
   ```
3. Enable push on the push-test channel so that `push.subscribeDevice` works:
   ```sh
   ably apps channel-rules create --name "push-test" --push-enabled
   ```
4. Open `LocalDeviceStorageBugTest.xcodeproj` in Xcode.
4. Build and run on a physical device (PushKit does not deliver tokens on the simulator).

To observe the events being published, subscribe to the `LocalDeviceStorageBugTest-events` channel (e.g. `ably channels subscribe LocalDeviceStorageBugTest-events`).

## Sending a VoIP push

The `send-voip-push.sh` script fetches the latest VoIP device token from the events channel and sends a push notification to APNs:

```sh
APNS_AUTH_KEY_PATH=~/path/to/AuthKey.p8 \
APNS_AUTH_KEY_ID=XXXXXXXXXX \
APNS_TEAM_ID=XXXXXXXXXX \
./send-voip-push.sh
```

This uses the sandbox APNs endpoint by default. Set `APNS_HOST=api.push.apple.com` for production.

## Known reproduction issues

- **iPad**: Sending a VoIP push to an iPad does not appear to show the incoming call screen or launch the app before first unlock. The same flow works on an iPhone. The reason is not yet known.
