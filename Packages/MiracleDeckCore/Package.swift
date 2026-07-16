// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MiracleDeckCore",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "MiracleDeckCore", targets: ["MiracleDeckCore"])
    ],
    targets: [
        .target(name: "MiracleDeckCore"),
        .testTarget(
            name: "MiracleDeckCoreTests",
            dependencies: ["MiracleDeckCore"]
        )
    ]
)
