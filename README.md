# Ably Pub/Sub Java SDK

Build any realtime experience using Ably’s Pub/Sub Java SDK. Supported on all popular platforms and frameworks, including Swift and Objective-C.

Ably Pub/Sub provides flexible APIs that deliver features such as pub-sub messaging, message history, presence, and push notifications. Utilizing Ably’s realtime messaging platform, applications benefit from its highly performant, reliable, and scalable infrastructure.

Find out more:

* [Ably Pub/Sub docs](https://ably.com/docs/basics)
* [Ably Pub/Sub examples](https://ably.com/examples?product=pubsub)

---

## Getting started

Everything you need to get started with Ably:

* [Quickstart in Pub/Sub using Swift](https://ably.com/docs/getting-started/quickstart?lang=swift)

---

## Supported platforms

Ably aims to support a wide range of platforms. If you experience any compatibility issues, open an issue in the repository or contact [Ably support](https://ably.com/support).

The following platforms are supported:

| Platform | Support |
|----------|---------|
| Swift | >= 5.3 |
| Objective-C | Xcode 7.3+ |
| iOS| >= 10.0 |
| tvOS | >= 10.0 |
| macOS| >= 10.12 |

> [!IMPORTANT]
> SDK Swift / Objective-C versions < 1.2.24 will be [deprecated](https://ably.com/docs/platform/deprecate/protocol-v1) from November 1, 2025.

---

## Known Limitations

This client library is currently *not compatible* with some of the Ably features:

| Feature |
| :--- |
| [Custom transportParams](https://ably.com/docs/realtime/usage#client-options) |
| [Remember fallback host during failures](https://ably.com/docs/realtime/usage#client-options) | 
| [ErrorInfo URLs to help debug issues](https://ably.com/docs/realtime/types#error-info) |

---

## Installation

You can install Ably for iOS and macOS through [Swift package manager](#swift-package-manager), [CocoaPods](#carthage), [Carthage](#carthage) or [install manually](#manual).

### Swift package manager

The Ably Pub/Sub SDK includes installation support for [Swift Package Manager](https://swift.org/package-manager/).

<details>
<summary>Swift package manager installation details.</summary>

To install the `ably-cocoa` package in your Xcode project: 

* Paste `https://github.com/ably/ably-cocoa` in the *Swift Packages* search box. ( *Xcode project*  &rarr;  *Swift Packages..* . &rarr; `+` button)
* Select the `Ably` SDK for your target.

To install the `ably-cocoa` package in another Swift package, add the following to your `Package.Swift`:

```swift
 .package(url: "https://github.com/ably/ably-cocoa", from: "1.2.25"),
```

See Apple's [adding package dependencies to your app](https://developer.apple.com/documentation/swift_packages/adding_package_dependencies_to_your_app) guide for more detail.
</details>

### CocoaPods

The Ably Pub/Sub SDK includes installation support for [CocoaPods](https://cocoapods.org/).

<details>
<summary>CocoaPods installation details.</summary>

If you intend to use Swift, using `use_frameworks!` in your Podfile is recommended (this will create a Framework that can be used in Swift natively).

Add this line to your application's Podfile:

```ruby
# For Xcode 7.3 and newer
pod 'Ably', '>= 1.2'
```

And then install the dependency:

```bash
$ pod install
```

</details>

### Carthage

The Ably Pub/Sub SDK includes installation support for [Carthage](https://github.com/Carthage/Carthage/).

<details>
<summary>Carthage installation details.</summary>

Add the following line to your application's Cartfile:

```ruby
# For Xcode 7.3 and newer
github "ably/ably-cocoa" >= 1.2
```

And then run one of the following commands required for your platform:

| Platform | Command |
|----------|---------|
| iOS | `carthage update --use-xcframeworks --platform iOS --no-use-binaries` |
| macOS | `carthage update --use-xcframeworks --platform macOS --no-use-binaries`|
| tvOS | `carthage update --use-xcframeworks --platform tvOS --no-use-binaries` |

After building the framework (located in `[PROJECT_ROOT]/Carthage/Build`), drag the following files into the **Frameworks**, **Libraries**, and **Embedded content** section of your Xcode target’s **General** tab:

* `Ably.xcframework`
* `AblyDeltaCodec.xcframework`
* `msgpack.xcframework`
* For applications, select **Embed & Sign**
* For other targets, select **Do Not Embed**

If you encounter an error like:

```
dyld: Library not loaded: @rpath/AblyDeltaCodec.framework/AblyDeltaCodec
```

you’ve likely missed adding one or more required dependencies. See [this Carthage guide](https://github.com/Carthage/Carthage#adding-frameworks-to-an-application) for more help.

</details>

### Manual install

The Ably Pub/Sub SDK includes manual installation support.

<details>
<summary>Manual installation details.</summary>

* Download the [Ably Pub/Sub Cocoa SDK](https://github.com/ably/ably-cocoa).
* Drag the ably-cocoa/ably-cocoa directory into your Xcode project as a group.

Ably depends on our [MessagePack Fork](https://github.com/ably-forks/msgpack-objective-C) 0.2.0; get it [from the releases page](https://github.com/ably-forks/msgpack-objective-C/releases/tag/0.2.0-ably-1) and link it into your project.

</details>

---

## Support, feedback and troubleshooting

Please visit https://support.ably.com/ for access to our knowledgebase and to ask for any assistance.

You can also view the [community reported Github issues](https://github.com/ably/ably-cocoa/issues).

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for details.
