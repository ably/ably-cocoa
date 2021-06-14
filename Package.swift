// swift-tools-version:5.4.0

import PackageDescription

let package = Package(
    name: "ably-cocoa",
    platforms: [
        .macOS(.v10_11),
        .iOS(.v9),
        .tvOS(.v10)
    ],
    products: [
        .executable(
            name: "Example",
            targets: ["Example"]
        ),
        .library(
            name: "Ably",
            targets: ["Ably"]
        ),
        .library(
            name: "SocketRocket",
            targets: ["SocketRocket"]
        )
    ],
    dependencies: [
        .package(name: "msgpack", url: "https://github.com/rvi/msgpack-objective-C", from: "0.4.0"),
        .package(name: "AblyDeltaCodec", url: "https://github.com/ably/delta-codec-cocoa", .branch("main"))
    ],
    targets: [
        .target(
            name: "Example",
            dependencies: [
            "Ably",
            "SocketRocket"
            ]
        ),
        .target(
            name: "Ably",
            dependencies: [
                .byName(name: "msgpack"),
                .byName(name: "AblyDeltaCodec"),
                "SocketRocket"
            ],
            cSettings: [
                .headerSearchPath("**"),
            ]
        ),
        .target(name: "SocketRocket",
                dependencies: [],
                cSettings: [
                    .headerSearchPath("**"),
                ]
        )
    ]
)
