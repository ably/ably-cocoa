// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "ably-cocoa",
    platforms: [
        .macOS(.v10_11),
        .iOS(.v9),
        .tvOS(.v10)
    ],
    products: [
        .library(
            name: "Ably",
            targets: ["Ably"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/rvi/msgpack-objective-C", from: "0.4.0"),
        .package(url: "https://github.com/ably/delta-codec-cocoa", from: "1.3.5"),
        .package(url: "https://github.com/quick/nimble", from: "11.2.2")
    ],
    targets: [
        // Private API of the core SDK, exposed to Ably-authored plugins. Formerly
        // the separate ably-cocoa-plugin-support repository; deliberately not
        // vended as a product.
        .target(
            name: "_AblyPluginSupportPrivate",
            path: "Sources/_AblyPluginSupportPrivate"
        ),
        .target(
            name: "Ably",
            dependencies: [
                .product(name: "msgpack", package: "msgpack-objective-C"),
                .product(name: "AblyDeltaCodec", package: "delta-codec-cocoa"),
                .target(name: "_AblyPluginSupportPrivate")
            ],
            path: "Source",
            exclude: [
                "Info-iOS.plist",
                "Info-tvOS.plist",
                "Info-macOS.plist"
            ],
            resources: [.copy("PrivacyInfo.xcprivacy")],
            publicHeadersPath: "include",
            cSettings: [
                .define("ABLY_SUPPORTS_PLUGINS"),
                .headerSearchPath("PrivateHeaders"),
                .headerSearchPath("PrivateHeaders/Ably"),
                .headerSearchPath("include/Ably"),
                .headerSearchPath("SocketRocket"),
                .headerSearchPath("SocketRocket/Internal"),
                .headerSearchPath("SocketRocket/Internal/Security"),
                .headerSearchPath("SocketRocket/Internal/Proxy"),
                .headerSearchPath("SocketRocket/Internal/Utilities"),
                .headerSearchPath("SocketRocket/Internal/RunLoop"),
                .headerSearchPath("SocketRocket/Internal/Delegate"),
                .headerSearchPath("SocketRocket/Internal/IOConsumer"),
            ]
        ),
        .testTarget(
            name: "AblyTests",
            dependencies: [
                .byName(name: "Ably"),
                .byName(name: "AblyTesting"),
                .byName(name: "AblyTestingObjC"),
                .product(name: "Nimble", package: "nimble"),
                .target(name: "_AblyPluginSupportPrivate")
            ],
            path: "Test/AblyTests",
            resources: [
                .copy("ably-common")
            ],
            swiftSettings: [
                // This test code predates the Swift 6 language mode.
                .swiftLanguageMode(.v5)
            ]
        ),
        // Universal Test Suite (UTS)
        // A standalone Swift Testing suite (import Testing / @Suite) derived from the language-neutral
        // specs in the `ably/specification` repo (uts/). Deliberately does not depend on Nimble or XCTest.
        .testTarget(
            name: "UTS",
            dependencies: [
                .byName(name: "Ably"),
                .target(name: "_AblyPluginSupportPrivate")
            ],
            path: "Test/UTS",
            exclude: [
                "README.md",
                "deviations.md"
            ],
            swiftSettings: [
                // Build the UTS suite in the Swift 6 language mode (strict concurrency checking) so the
                // compiler catches data races in the harness/tests. Only affects this test target (not
                // the shipped product).
                .swiftLanguageMode(.v6)
            ]
        ),
        // A handful of tests written in Objective-C (they can't be part of AblyTests because SPM doesn't allow mixed-language targets).
        .testTarget(
            name: "AblyTestsObjC",
            dependencies: [
                .byName(name: "Ably"),
                .byName(name: "AblyTesting"),
                .byName(name: "AblyTestingObjC"),
            ],
            path: "Test/AblyTestsObjC"
        ),
        // Provides test helpers used by both AblyTests and AblyTestsObjC.
        .target(
            name: "AblyTesting",
            dependencies: [
                .byName(name: "Ably"),
            ],
            path: "Test/AblyTesting",
            swiftSettings: [
                // This test code predates the Swift 6 language mode.
                .swiftLanguageMode(.v5)
            ]
        ),
        // Provides test helpers written in Objective-C (they can't be part of AblyTests because SPM doesn't allow mixed-language targets).
        .target(
            name: "AblyTestingObjC",
            path: "Test/AblyTestingObjC",
            cSettings: [
                .headerSearchPath("Dependencies/steipete"),
            ]
        )
    ]
)

