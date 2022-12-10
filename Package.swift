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
        .package(name: "AblyDeltaCodec", url: "https://github.com/ably/delta-codec-cocoa", from: "1.3.3")
    ],
    targets: [
        .target(
            name: "SocketRocket",
            path: "SocketRocket/SocketRocket",
            publicHeadersPath: ".",
            cSettings: [
                .headerSearchPath("Internal"),
                .headerSearchPath("Internal/Security"),
                .headerSearchPath("Internal/Proxy"),
                .headerSearchPath("Internal/Utilities"),
                .headerSearchPath("Internal/RunLoop"),
                .headerSearchPath("Internal/Delegate"),
                .headerSearchPath("Internal/IOConsumer"),
                /*
                This is a quick solution that allows us to access the Ably
                logger types from inside SocketRocket. I think a neater
                solution might be to remove this separation and move the
                SocketRocket code into the Ably target so that they can share
                types freely, but I think this is OK for now.
                */
                .headerSearchPath("../../Source/include/Ably"), // For the #import "ARTLog.h" in ARTSRLog.m
                .headerSearchPath("../../Source/include") // For the #import <Ably/ARTTypes.h> in the ARTLog.h imported by ARTSRLog.m
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
            exclude: [
                "Info-iOS.plist",
                "Info-tvOS.plist",
                "Info-macOS.plist"
            ],
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("PrivateHeaders"),
                .headerSearchPath("PrivateHeaders/Ably"),
                .headerSearchPath("include/Ably")
            ]
        )
    ]
)

