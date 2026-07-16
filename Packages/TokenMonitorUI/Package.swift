// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "TokenMonitorUI",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "TokenMonitorUI", targets: ["TokenMonitorUI"])
    ],
    dependencies: [
        .package(path: "../TokenMonitorCore")
    ],
    targets: [
        .target(
            name: "TokenMonitorUI",
            dependencies: ["TokenMonitorCore"]
        ),
        .testTarget(
            name: "TokenMonitorUITests",
            dependencies: ["TokenMonitorUI", "TokenMonitorCore"]
        )
    ]
)
