// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MiracleDeckUI",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "MiracleDeckUI", targets: ["MiracleDeckUI"])
    ],
    dependencies: [
        .package(path: "../MiracleDeckCore"),
        .package(path: "../MiracleDeckProviders")
    ],
    targets: [
        .target(
            name: "MiracleDeckUI",
            dependencies: ["MiracleDeckCore"],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "MiracleDeckUITests",
            dependencies: [
                "MiracleDeckUI",
                "MiracleDeckCore",
                "MiracleDeckProviders"
            ]
        )
    ]
)
