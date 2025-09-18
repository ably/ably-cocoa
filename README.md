![Ably LiveObjects Swift Header](images/SwiftSDK-LiveObjects-github.png)
[![SPM Swift Compatibility](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fably%2Fably-liveobjects-swift-plugin%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/ably/ably-liveobjects-swift-plugin)
[![License](https://badgen.net/github/license/ably/ably-liveobjects-swift-plugin)](https://github.com/ably/ably-liveobjects-swift-plugin/blob/main/LICENSE)

---

# Ably LiveObjects Swift plugin

The Ably LiveObjects plugin enables real-time collaborative data synchronization for the [ably-cocoa](https://github.com/ably/ably-cocoa/) SDK. LiveObjects provides a simple way to build collaborative applications with synchronized state across multiple clients in real-time. Built on [Ably's](https://ably.com/) core service, it abstracts complex details to enable efficient collaborative architectures.

> [!WARNING]
> This plugin is currently experimental and the public API may change.

---

## Getting started

Everything you need to get started with Ably LiveObjects:

- [Learn about Ably LiveObjects.](https://ably.com/docs/liveobjects)
- [Getting started with LiveObjects in Swift.](https://ably.com/docs/liveobjects/quickstart/swift)
- Explore the [example app](Example) to see LiveObjects in action.

---

## Supported platforms

Ably aims to support a wide range of platforms. If you experience any compatibility issues, open an issue in the repository or contact [Ably support](https://ably.com/support).

This plugin supports the following platforms:

| Platform | Support |
| -------- | ------- |
| iOS      | >= 14.0 |
| macOS    | >= 11.0 |
| tvOS     | >= 14.0 |

> [!NOTE]
> Xcode 16.3 or later is required.

---

## Example app

This repository contains an example app, written using SwiftUI, which demonstrates how to use the plugin. The code for this app is in the [`Example`](Example) directory.

In order to allow the app to use modern SwiftUI features, it supports the following OS versions:

- macOS 14 and above
- iOS 17 and above
- tvOS 17 and above

To run the app:

1. Open the `AblyLiveObjects.xcworkspace` workspace in Xcode.
2. Follow the instructions inside the `Secrets.example.swift` file to add your Ably API key to the example app.
3. Run the `AblyLiveObjectsExample` target. If you wish to run it on an iOS or tvOS device, you'll need to set up code signing.

---

## Releases

The [CHANGELOG.md](./CHANGELOG.md) contains details of the latest releases for this plugin. You can also view all Ably releases on [changelog.ably.com](https://changelog.ably.com).

---

## Contribute

Read the [CONTRIBUTING.md](./CONTRIBUTING.md) guidelines to contribute to Ably or [share feedback or request a new feature](https://forms.gle/mBw9M53NYuCBLFpMA).

## Support, feedback and troubleshooting

For help or technical support, visit Ably's [support page](https://ably.com/support). You can also view the [community reported GitHub issues](https://github.com/ably/ably-liveobjects-swift-plugin/issues) or raise one yourself.
