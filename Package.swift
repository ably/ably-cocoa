// swift-tools-version:5.3.0

import PackageDescription

let package = Package(
    name: "Ably",
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
        .package(name: "AblyDeltaCodec", url: "https://github.com/ably/delta-codec-cocoa", from: "1.3.0")
    ],
    targets: [
        .target(
            name: "Ably",
            dependencies: [
                .byName(name: "msgpack"),
                .byName(name: "AblyDeltaCodec")
            ],
            path: ".",
            exclude: [
                "Info-tvOS.plist",
                "Info-macOS.plist",
                "Info-iOS.plist",
                "Ably-SoakTest-App",
                "Ably-SoakTest-AppUITests",
                "Spec",
                "Products",
                "Scripts",
                "fastlane",
                "Examples",
                "Carthage",
                "include/SocketRocketAblyFork",
                "Makefile",
                "test-resources",
                "ably-common/test-resources",
                "Ably.xcconfig",
                "Cartfile",
                "Cartfile.private",
                "Cartfile.resolved",
                "Gemfile",
                "Gemfile.lock",
                "Ably.podspec",
                "Version.xcconfig",
                "ably-common/protocol/README.md"
            ],
            sources: [
                "Source",
                "SocketRocket"
            ],
            resources: [
                .copy("COPYRIGHT"),
                .copy("CHANGELOG.md"),
                .copy("README.md"),
                .copy("MAINTAINERS.md"),
                .copy("LICENSE"),
                .copy("ably-common/protocol/errors.json"),
                .copy("ably-common/protocol/errorsHelp.json")
            ],
            publicHeadersPath: "Source/include",
            cSettings: [
                .headerSearchPath("include"),
                .headerSearchPath("Source/**"),
                .headerSearchPath("SocketRocket/**")
            ]
        )
    ]
)

