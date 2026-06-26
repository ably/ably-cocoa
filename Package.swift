// swift-tools-version:5.3.0

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
        .library(
            name: "ably-liveobjects-swift",
            targets: ["ably-liveobjects-swift"]
        ),
    ],
    dependencies: [
        .package(name: "msgpack", url: "https://github.com/rvi/msgpack-objective-C", from: "0.4.0"),
        .package(name: "AblyDeltaCodec", url: "https://github.com/ably/delta-codec-cocoa", from: "1.3.5"),
        .package(name: "Nimble", url: "https://github.com/quick/nimble", from: "11.2.2"),
        .package(name: "ably-cocoa-plugin-support", url: "https://github.com/ably/ably-cocoa-plugin-support.git", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "Ably",
            dependencies: [
                .byName(name: "msgpack"),
                .byName(name: "AblyDeltaCodec"),
                .product(name: "_AblyPluginSupportPrivate", package: "ably-cocoa-plugin-support")
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
        // Experimental Swift-native public API for LiveObjects (path objects / instances).
        // A skeleton: every public type is defined but unimplemented (traps at runtime). Built in the
        // Swift 6 language mode for strict concurrency checking.
        .target(
            name: "ably-liveobjects-swift",
            dependencies: [
                .byName(name: "Ably"),
            ],
            path: "ably-liveobjects-swift",
            swiftSettings: [
                .unsafeFlags(["-swift-version", "6"])
            ]
        ),
        .testTarget(
            name: "AblyTests",
            dependencies: [
                .byName(name: "Ably"),
                .byName(name: "AblyTesting"),
                .byName(name: "AblyTestingObjC"),
                .byName(name: "Nimble"),
                .product(name: "_AblyPluginSupportPrivate", package: "ably-cocoa-plugin-support")
            ],
            path: "Test/AblyTests",
            resources: [
                .copy("ably-common")
            ]
        ),
        // Universal Test Suite (UTS)
        // A standalone Swift Testing suite (import Testing / @Suite) derived from the language-neutral
        // specs in the `ably/specification` repo (uts/). Deliberately does not depend on Nimble or XCTest.
        .testTarget(
            name: "UTS",
            dependencies: [
                .byName(name: "Ably"),
                .product(name: "_AblyPluginSupportPrivate", package: "ably-cocoa-plugin-support")
            ],
            path: "Test/UTS",
            exclude: [
                "README.md",
                "deviations.md"
            ],
            swiftSettings: [
                // Build the UTS suite in the Swift 6 language mode (strict concurrency checking) so the
                // compiler catches data races in the harness/tests. The package manifest is still
                // swift-tools-version 5.3, which predates `.swiftLanguageMode`, so this is applied via
                // the compiler flag. Only affects this test target (not the shipped product).
                .unsafeFlags(["-swift-version", "6"])
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
            path: "Test/AblyTesting"
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

