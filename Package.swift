// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let aiUICollectionSwiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("StrictConcurrency"),
    .swiftLanguageMode(.v6),
]

let package = Package(
    name: "UICollection",
    platforms: [
        .iOS("27.0"),
        .macOS("27.0"),
        .visionOS("27.0"),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "UICollection",
            targets: ["UICollection"]
        ),
        .library(
            name: "AIUICollection",
            targets: ["AIUICollection"]
        ),
    ],
    dependencies: [
        .package(path: "../AIToolKit"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "UICollection",
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "AIUICollection",
            dependencies: [
                .product(name: "AIToolKit", package: "AIToolKit"),
            ],
            resources: [
                .process("Resources")
            ],
            swiftSettings: aiUICollectionSwiftSettings
        ),
        .testTarget(
            name: "UICollectionTests",
            dependencies: ["UICollection"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
