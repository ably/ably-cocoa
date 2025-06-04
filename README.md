# Ably LiveObjects plugin for ably-cocoa SDK

This is a work in progress plugin that enables LiveObjects functionality in the [ably-cocoa](https://github.com/ably/ably-cocoa/) SDK. It is not yet ready to be used.

## Supported Platforms

- macOS 11 and above
- iOS 14 and above
- tvOS 14 and above

## Requirements

Xcode 16.3 or later.

## Installation

For now, here is a code snippet demonstrating how, after installing this package and ably-cocoa using Swift Package Manager, you can set up the LiveObjects plugin and access its functionality.

```swift
import Ably
import AblyLiveObjects

let clientOptions = ARTClientOptions(key: /* <insert your Ably API key here> */)
clientOptions.plugins = [.liveObjects: AblyLiveObjects.Plugin.self]

let realtime = ARTRealtime(options: clientOptions)

// You can now access LiveObjects functionality via a channel's `objects` property:
let channel = realtime.channels.get("myChannel")
let rootObject = try await channel.objects.getRoot()
// …and so on
```

## Example app

This repository contains an example app, written using SwiftUI, which demonstrates how to use the SDK. The code for this app is in the [`Example`](Example) directory.

In order to allow the app to use modern SwiftUI features, it supports the following OS versions:

- macOS 14 and above
- iOS 17 and above
- tvOS 17 and above

To run the app:

1. Open the `AblyLiveObjects.xcworkspace` workspace in Xcode.
2. Follow the instructions inside the `Secrets.example.swift` file to add your Ably API key to the example app.
3. Run the `AblyLiveObjectsExample` target. If you wish to run it on an iOS or tvOS device, you’ll need to set up code signing.

## Contributing

For guidance on how to contribute to this project, see the [contributing guidelines](CONTRIBUTING.md).
