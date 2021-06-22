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
    ],
    dependencies: [
        .package(name: "msgpack", url: "https://github.com/rvi/msgpack-objective-C", from: "0.4.0"),
        .package(name: "AblyDeltaCodec", url: "https://github.com/ably/delta-codec-cocoa", .branch("main"))
    ],
    targets: [
        .target(
            name: "SocketRocket",
            path: "SocketRocket/SocketRocket",
            publicHeadersPath: ".",
            cSettings: [
                .headerSearchPath("**")
            ]
        ),
        .target(
            name: "Ably",
            dependencies: [
                "SocketRocket",
                .byName(name: "msgpack"),
                .byName(name: "AblyDeltaCodec")
            ],
            path: "Source",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("PrivateHeaders/**"),
                .headerSearchPath("include/Ably")
            ]
        )
    ]
)

