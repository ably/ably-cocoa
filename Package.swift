// swift-tools-version:5.3.0

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
    ],
    dependencies: [
        .package(name: "msgpack", url: "https://github.com/rvi/msgpack-objective-C", from: "0.4.0"),
        .package(name: "AblyDeltaCodec", url: "https://github.com/ably/delta-codec-cocoa", from: "1.3.3"),
        .package(name: "Nimble", url: "https://github.com/quick/nimble", from: "11.2.2"),
        .package(name: "ably-cocoa-plugin-support", url: "https://github.com/ably/ably-cocoa-plugin-support", .revision("2ce1058ed4430cc3563dcead0299e92a81d2774b")),
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
            resources: [.copy("PrivacyInfo.xcprivacy")],
            publicHeadersPath: "include",
            cSettings: [
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
                .byName(name: "Nimble"),
            ],
            path: "Test/AblyTests",
            resources: [
                .copy("ably-common")
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

