// swift-tools-version:5.3.0

import PackageDescription

let otherProducts: [Product] = (1..<4).map { i in
    Product.library(
        name: "_AblyPlugin\(i)",
        targets: ["AblyPlugin"]
    )
}

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
        // This library should only be used by Ably-authored plugins.
        .library(
            name: "_AblyPlugin",
            targets: ["AblyPlugin"]
        ),
    ] + otherProducts,
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
                .headerSearchPath("../AblyPlugin/include"),
                .headerSearchPath("../AblyPlugin/PrivateHeaders"),
            ]
        ),
        .target(
            name: "AblyPlugin",
            dependencies: [
                .byName(name: "Ably")
            ],
            path: "AblyPlugin",
            cSettings: [
                .headerSearchPath("PrivateHeaders"),
                .headerSearchPath("../Source/PrivateHeaders"),
                .headerSearchPath("../Source/PrivateHeaders/Ably")
            ]
        )
    ]
)

