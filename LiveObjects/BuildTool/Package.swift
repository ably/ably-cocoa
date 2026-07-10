// swift-tools-version: 6.1

// A command-line tool used by LiveObjects development and CI (linting,
// generating CI matrices, and driving xcodebuild). Run it from the
// LiveObjects directory:
//
//     swift run --package-path BuildTool BuildTool <subcommand>
//
// This is a separate package, rather than a target of the root ably-cocoa
// package, so that its dependencies are not resolved by consumers of
// ably-cocoa.

import PackageDescription

let package = Package(
    name: "BuildTool",
    platforms: [
        .macOS(.v14),
    ],
    dependencies: [
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
    ],
    targets: [
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
            path: "Sources",
        ),
    ],
)
