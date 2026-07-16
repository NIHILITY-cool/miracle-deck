// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MiracleDeckProviders",
    platforms: [.macOS(.v14)],
    products: [
        .library(
            name: "MiracleDeckProviders",
            targets: ["MiracleDeckProviders"]
        )
    ],
    dependencies: [
        .package(path: "../MiracleDeckCore")
    ],
    targets: [
        .target(
            name: "MiracleDeckProviders",
            dependencies: ["MiracleDeckCore"]
        ),
        .testTarget(
            name: "MiracleDeckProvidersTests",
            dependencies: ["MiracleDeckProviders"]
        )
    ]
)
