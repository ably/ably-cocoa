# LocalDeviceStorageBugTest

A minimal iOS app for investigating push registration failures in ably-cocoa.

## How it works

The app creates two Ably client instances:

- **`mainAbly`** (`ARTRealtime`) — the client under test.
- **`eventLoggingAbly`** (`ARTRealtime`) — used solely to log events emitted by the app, by publishing them to the `LocalDeviceStorageBugTest-events` channel. Uses a Realtime connection to preserve message ordering.

### Events currently logged

- **Log messages from `mainAbly`**: A custom `ARTLog` subclass (`EventLoggingLogHandler`) is set as the main client's `logHandler`. Every log message is published to the events channel with event name `log` and a JSON payload containing `level` and `message`.

## Setup

1. Copy `Secrets.example.swift` to `LocalDeviceStorageBugTest/Secrets.swift` and insert your Ably API key. (`Secrets.swift` is gitignored.)
2. Open `LocalDeviceStorageBugTest.xcodeproj` in Xcode.
3. Build and run on a device or simulator.

To observe the events being published, subscribe to the `LocalDeviceStorageBugTest-events` channel using another client (e.g. the Ably CLI or dashboard).
