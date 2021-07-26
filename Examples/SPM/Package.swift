// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import Darwin.C

// Setup ENV variables when using with Xcode IDE
//
//setenv("PACKAGE_URL", "", 1)
//setenv("PACKAGE_REVISION", "", 1)

func env(_ name: String) -> String? {
    if let envPointer = getenv(name) {
        return String(cString: envPointer)
    } else {
        print("Can't find environment \(name)")
        return nil
    }
}

guard let packageURL = env("PACKAGE_URL"), let revision = env("PACKAGE_REVISION") else {
    exit(0)
}

let package = Package(
    name: "SPMIntegration",
    platforms: [
        .iOS(.v9),
        .macOS(.v10_11)
    ],
    dependencies: [
        .package(name:"ably-cocoa", url: packageURL, .revision(revision))
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
