# LocalDeviceStorageBugTest

A minimal iOS app for investigating push registration failures in ably-cocoa.

## How it works

The app creates two Ably client instances:

- **`mainAbly`** (`ARTRealtime`) — the client under test.
- **`eventLoggingAbly`** (`ARTRealtime`) — used solely to log events emitted by the app, by publishing them to the `LocalDeviceStorageBugTest-events` channel. Uses a Realtime connection to preserve message ordering.

### VoIP push

The app registers for VoIP pushes via PushKit. This gives us a way to deterministically launch the app before first unlock, which is important for reproducing the bug under investigation. A minimal CallKit handler is included to satisfy the iOS requirement that VoIP pushes must report an incoming call.

### Events

All events published to the channel are defined by the `Event` enum in `Event.swift`. Current events:

- **`ablyLog`** — a log message from the SDK (level and message text), captured via a custom `ARTLog` handler on `mainAbly`.
- **`voipTokenUpdated`** — PushKit provided a new VoIP device token.
- **`voipPushReceived`** — a VoIP push notification was received.
- **`voipTokenInvalidated`** — PushKit invalidated the VoIP device token.

## Setup

1. Copy `Secrets.example.swift` to `LocalDeviceStorageBugTest/Secrets.swift` and insert your Ably API key. (`Secrets.swift` is gitignored.)
2. Open `LocalDeviceStorageBugTest.xcodeproj` in Xcode.
3. Build and run on a physical device (PushKit does not deliver tokens on the simulator).

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
