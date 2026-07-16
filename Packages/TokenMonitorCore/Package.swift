// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "TokenMonitorCore",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "TokenMonitorCore", targets: ["TokenMonitorCore"])
    ],
    targets: [
        .target(name: "TokenMonitorCore"),
        .testTarget(
            name: "TokenMonitorCoreTests",
            dependencies: ["TokenMonitorCore"]
        )
    ]
)
