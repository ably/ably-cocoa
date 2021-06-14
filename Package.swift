// swift-tools-version:5.4.0

import PackageDescription

let package = Package(
    name: "ably-cocoa",
    platforms: [
        .macOS(.v10_10),
        .iOS(.v9),
        .tvOS(.v10)
    ],
    products: [
        .library(
            name: "Ably",
            targets: ["Ably"]
        )
    ],
    dependencies: [
        .package(name: "msgpack", url: "https://github.com/rvi/msgpack-objective-C", from: "0.4.0"),
        .package(name: "AblyDeltaCodec", url: "https://github.com/ably/delta-codec-cocoa", .branch("main"))
    ],
    targets: [
        .target(
            name: "Ably",
            dependencies: [
                .byName(name: "msgpack"),
                .byName(name: "AblyDeltaCodec"),
                "SocketRocket"
            ],
            exclude: ["Info-tvOS.plist", "Info-macOS.plist", "Info-iOS.plist"]
        ),
        .target(name: "SocketRocket",
                dependencies: [],
                cSettings: [
                    .headerSearchPath("Sources/SocketRocket/Internal/Delegate/"),
                    .headerSearchPath("Sources/SocketRocket/Internal/Proxy/"),
                    .headerSearchPath("Sources/SocketRocket/Internal/"),
                    .headerSearchPath("Sources/SocketRocket/**")
                            ]
               )
    ]
)
