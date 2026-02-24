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
        // TODO: Unpin before release
        .package(
            url: "https://github.com/ably/ably-cocoa.git",
            revision: "460c1d11333dd58bbc924a3d153d1364b39bbdf0",
        ),
        // TODO: Unpin before release
        .package(
            url: "https://github.com/ably/ably-cocoa-plugin-support",
            revision: "f2468ee39f3e18955b0ec4fe41dc5a9906a72633",
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
