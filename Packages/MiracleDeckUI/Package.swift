// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MiracleDeckUI",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "MiracleDeckUI", targets: ["MiracleDeckUI"])
    ],
    dependencies: [
        .package(path: "../MiracleDeckCore")
    ],
    targets: [
        .target(
            name: "MiracleDeckUI",
            dependencies: ["MiracleDeckCore"]
        ),
        .testTarget(
            name: "MiracleDeckUITests",
            dependencies: ["MiracleDeckUI", "MiracleDeckCore"]
        )
    ]
)
