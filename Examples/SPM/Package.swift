// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import Darwin.C

let package = Package(
    name: "SPMIntegration",
    platforms: [
        .iOS(.v9),
        .macOS(.v10_11)
    ],
    dependencies: [
        .package(path: "../../")
    ],
    targets: [
        .target(
            name: "SPMIntegration",
            dependencies: [
                .product(name: "Ably", package: "ably-cocoa")
            ]),
        .testTarget(
            name: "SPMTests",
            dependencies: ["SPMIntegration"]),
    ]
)
