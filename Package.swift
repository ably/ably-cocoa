// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "ably-cocoa",
    platforms: [
        .macOS(.v11),
        .iOS(.v14),
        .tvOS(.v14),
    ],
    products: [
        .library(
            name: "Ably",
            targets: ["Ably"]
        ),
        .library(
            name: "AblySwift",
            targets: ["AblySwift"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/rvi/msgpack-objective-C", from: "0.4.0"),
        .package(url: "https://github.com/ably/delta-codec-cocoa", from: "1.3.3"),
        .package(url: "https://github.com/quick/nimble", from: "11.2.2"),
        .package(url: "https://github.com/ably/ably-cocoa-plugin-support", revision: "2ce1058ed4430cc3563dcead0299e92a81d2774b"),
    ],
    targets: [
        .target(
            name: "Ably",
            dependencies: [
                "SocketRocket",
                .product(name: "msgpack", package: "msgpack-objective-c"),
                .product(name: "AblyDeltaCodec", package: "delta-codec-cocoa"),
                .product(name: "_AblyPluginSupportPrivate", package: "ably-cocoa-plugin-support")
            ],
            resources: [.copy("PrivacyInfo.xcprivacy")],
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("PrivateHeaders"),
                .headerSearchPath("PrivateHeaders/Ably"),
                .headerSearchPath("include/Ably"),
            ]
        ),
        .target(
            name: "AblySwift",
            dependencies: [
                "SocketRocket",
                .product(name: "msgpack", package: "msgpack-objective-c"),
                .product(name: "AblyDeltaCodec", package: "delta-codec-cocoa"),
                .product(name: "_AblyPluginSupportPrivate", package: "ably-cocoa-plugin-support")
            ],
            resources: [.copy("PrivacyInfo.xcprivacy")],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .target(
            name: "SocketRocket",
            publicHeadersPath: ".",
            cSettings: [
                .headerSearchPath("Internal"),
                .headerSearchPath("Internal/Security"),
                .headerSearchPath("Internal/Proxy"),
                .headerSearchPath("Internal/Utilities"),
                .headerSearchPath("Internal/RunLoop"),
                .headerSearchPath("Internal/Delegate"),
                .headerSearchPath("Internal/IOConsumer"),
            ]
        ),
        .testTarget(
            name: "AblyTests",
            dependencies: [
                "Ably",
                "AblyTesting",
                "AblyTestingObjC",
                .product(name: "Nimble", package: "nimble"),
            ],
            path: "Test/AblyTests",
            resources: [
                .copy("ably-common")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        // A handful of tests written in Objective-C (they can't be part of AblyTests because SPM doesn't allow mixed-language targets).
        .testTarget(
            name: "AblyTestsObjC",
            dependencies: [
                "Ably",
                "AblyTesting",
                "AblyTestingObjC",
            ],
            path: "Test/AblyTestsObjC"
        ),
        // Provides test helpers used by both AblyTests and AblyTestsObjC.
        .target(
            name: "AblyTesting",
            dependencies: [
                "Ably",
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

