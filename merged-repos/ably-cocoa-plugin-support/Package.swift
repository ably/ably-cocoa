// swift-tools-version:5.3.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

// The swift-tools-version should not be increased above that of any of the packages that depend on this package (at the time of writing that is ably-cocoa and the LiveObjects plugin), so as not to inadvertently increase the required tooling version of those packages.

import PackageDescription

let package = Package(
    name: "ably-cocoa-plugin-support",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "_AblyPluginSupportPrivate",
            targets: ["_AblyPluginSupportPrivate"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "_AblyPluginSupportPrivate"),
    ]
)
