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
        .library(
            name: "AblyLiveObjects",
            targets: ["AblyLiveObjects"]
        ),
    ],
    dependencies: [
        .package(name: "msgpack", url: "https://github.com/rvi/msgpack-objective-C", from: "0.4.0"),
        .package(name: "AblyDeltaCodec", url: "https://github.com/ably/delta-codec-cocoa", from: "1.3.5"),
        .package(name: "Nimble", url: "https://github.com/quick/nimble", from: "11.2.2"),
        // The next three are used only by the LiveObjectsBuildTool
        // executable target, which is a developer/CI tool. None of them are
        // linked into the Ably or AblyLiveObjects library products.
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
        .package(url: "https://github.com/apple/swift-async-algorithms", from: "1.0.1"),
        .package(url: "https://github.com/JanGorman/Table.git", from: "1.1.1"),
    ],
    targets: [
        // Private plugin-support API surface used by Ably-authored plugins
        // (e.g. AblyLiveObjects). Folded in from the former
        // ably-cocoa-plugin-support package.
        .target(
            name: "_AblyPluginSupportPrivate",
            path: "merged-repos/ably-cocoa-plugin-support/Sources/_AblyPluginSupportPrivate"
        ),
        .target(
            name: "Ably",
            dependencies: [
                .byName(name: "msgpack"),
                .byName(name: "AblyDeltaCodec"),
                .byName(name: "_AblyPluginSupportPrivate"),
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
        // LiveObjects functionality, folded in from the former
        // ably-liveobjects-swift-plugin package. Requires a higher OS floor
        // than ably-cocoa's package-wide minimum — gated via @available
        // on public/internal declarations rather than per-target platforms
        // (which SPM does not support).
        .target(
            name: "AblyLiveObjects",
            dependencies: [
                .byName(name: "Ably"),
                .byName(name: "_AblyPluginSupportPrivate"),
            ],
            path: "merged-repos/ably-liveobjects-swift-plugin/Sources/AblyLiveObjects",
            exclude: [
                ".swiftformat",
                ".swiftlint.yml",
            ]
        ),
        .testTarget(
            name: "AblyLiveObjectsTests",
            dependencies: [
                .byName(name: "AblyLiveObjects"),
                .byName(name: "Ably"),
                .byName(name: "_AblyPluginSupportPrivate"),
            ],
            path: "merged-repos/ably-liveobjects-swift-plugin/Tests/AblyLiveObjectsTests",
            exclude: [
                ".swiftformat",
                ".swiftlint.yml",
                "CLAUDE.md",
            ],
            resources: [
                .copy("ably-common"),
            ]
        ),
        // Developer/CI tooling — drives the test runner across platforms,
        // fetches simulator destinations, etc. Folded in from the former
        // ably-liveobjects-swift-plugin package. Not a library product, so
        // it is not visible to consumers and its transitive deps
        // (swift-argument-parser, swift-async-algorithms, Table) do not
        // affect them at build time.
        .executableTarget(
            name: "LiveObjectsBuildTool",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
                .product(name: "Table", package: "Table"),
            ],
            path: "merged-repos/ably-liveobjects-swift-plugin/Sources/BuildTool"
        ),
        .testTarget(
            name: "AblyTests",
            dependencies: [
                .byName(name: "Ably"),
                .byName(name: "AblyTesting"),
                .byName(name: "AblyTestingObjC"),
                .byName(name: "Nimble"),
                .byName(name: "_AblyPluginSupportPrivate"),
            ],
            path: "Test/AblyTests",
            resources: [
                .copy("ably-common")
            ],
            // Pre-existing test code is written against Swift 5 mode; the
            // tools-version bump to 6.1 would otherwise promote the
            // existing strict-concurrency warnings to errors.
            swiftSettings: [.swiftLanguageMode(.v5)]
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
            path: "Test/AblyTesting",
            swiftSettings: [.swiftLanguageMode(.v5)]
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
