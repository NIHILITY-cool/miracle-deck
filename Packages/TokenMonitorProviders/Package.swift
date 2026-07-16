// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "TokenMonitorProviders",
    platforms: [.macOS(.v14)],
    products: [
        .library(
            name: "TokenMonitorProviders",
            targets: ["TokenMonitorProviders"]
        )
    ],
    dependencies: [
        .package(path: "../TokenMonitorCore")
    ],
    targets: [
        .target(
            name: "TokenMonitorProviders",
            dependencies: ["TokenMonitorCore"]
        ),
        .testTarget(
            name: "TokenMonitorProvidersTests",
            dependencies: ["TokenMonitorProviders"]
        )
    ]
)
