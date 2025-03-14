// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LullzBreathing",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "LullzBreathing",
            targets: ["LullzBreathing"]),
    ],
    dependencies: [
        .package(path: "../LullzCore"),
        .package(path: "../LullzUI"),
        .package(path: "../LullzModels")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "LullzBreathing",
            dependencies: [
                "LullzCore",
                "LullzUI",
                "LullzModels"
            ]),
        .testTarget(
            name: "LullzBreathingTests",
            dependencies: ["LullzBreathing"]
        ),
    ]
)
