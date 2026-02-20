// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ObjectGestures",
    platforms: [
        .iOS(.v18),
        .visionOS(.v2),
        .macOS(.v14)
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
