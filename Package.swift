// swift-tools-version:5.3.0

import PackageDescription

let package = Package(
    name: "ably-cocoa",
    platforms: [
        .macOS(.v10_11),
        .iOS(.v13),
        .tvOS(.v10)
    ],
    products: [
        .library(
            name: "Ably",
            targets: ["Ably"]
        ),
    ],
    dependencies: [
        .package(name: "msgpack", url: "https://github.com/rvi/msgpack-objective-C", from: "0.4.0"),
        .package(name: "AblyDeltaCodec", url: "https://github.com/ably/delta-codec-cocoa", from: "1.3.3")
    ],
    targets: [
        .target(
            name: "Ably",
            dependencies: [
                .byName(name: "msgpack"),
                .byName(name: "AblyDeltaCodec")
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
        )
    ]
)

