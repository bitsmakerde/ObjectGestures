// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ObjectGestures",
    platforms: [
        .iOS(.v26),
        .visionOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "ObjectGestures",
            targets: ["ObjectGestures"]
        )
    ],
    targets: [
        .target(
            name: "ObjectGestures",
            dependencies: []
        ),
        .testTarget(
            name: "ObjectGesturesTests",
            dependencies: ["ObjectGestures"]
        )
    ]
)
