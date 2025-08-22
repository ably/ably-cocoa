// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "AblyLiveObjects",
    platforms: [
        .macOS(.v11),
        .iOS(.v14),
        .tvOS(.v14),
    ],
    products: [
        .library(
            name: "AblyLiveObjects",
            targets: [
                "AblyLiveObjects",
            ],
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/ably/ably-cocoa",
            // TODO: Unpin before launch (https://github.com/ably/ably-liveobjects-swift-plugin/issues/75)
            revision: "b0c2ecf9da993736297b6986be5610b375440a3f",
        ),
        .package(
            url: "https://github.com/ably/ably-cocoa-plugin-support",
            from: "0.1.0",
        ),
        .package(
            url: "https://github.com/apple/swift-argument-parser",
            from: "1.5.0",
        ),
        .package(
            url: "https://github.com/apple/swift-async-algorithms",
            from: "1.0.1",
        ),
        .package(
            url: "https://github.com/JanGorman/Table.git",
            from: "1.1.1",
        ),
        .package(
            url: "https://github.com/apple/swift-docc-plugin",
            from: "1.0.0",
        ),
    ],
    targets: [
        .target(
            name: "AblyLiveObjects",
            dependencies: [
                .product(
                    name: "Ably",
                    package: "ably-cocoa",
                ),
                .product(
                    name: "_AblyPluginSupportPrivate",
                    package: "ably-cocoa-plugin-support",
                ),
            ],
        ),
        .testTarget(
            name: "AblyLiveObjectsTests",
            dependencies: [
                "AblyLiveObjects",
                .product(
                    name: "Ably",
                    package: "ably-cocoa",
                ),
                .product(
                    name: "_AblyPluginSupportPrivate",
                    package: "ably-cocoa-plugin-support",
                ),
            ],
            resources: [
                .copy("ably-common"),
            ],
        ),
        .executableTarget(
            name: "BuildTool",
            dependencies: [
                .product(
                    name: "ArgumentParser",
                    package: "swift-argument-parser",
                ),
                .product(
                    name: "AsyncAlgorithms",
                    package: "swift-async-algorithms",
                ),
                .product(
                    name: "Table",
                    package: "Table",
                ),
            ],
        ),
    ],
)
