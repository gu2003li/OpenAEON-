// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "OpenAEONKit",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(name: "OpenAEONProtocol", targets: ["OpenAEONProtocol"]),
        .library(name: "OpenAEONKit", targets: ["OpenAEONKit"]),
        .library(name: "OpenAEONChatUI", targets: ["OpenAEONChatUI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/steipete/ElevenLabsKit", exact: "0.1.0"),
        .package(url: "https://github.com/gonzalezreal/textual", exact: "0.3.1"),
    ],
    targets: [
        .target(
            name: "OpenAEONProtocol",
            path: "Sources/OpenAEONProtocol",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        .target(
            name: "OpenAEONKit",
            dependencies: [
                "OpenAEONProtocol",
                .product(name: "ElevenLabsKit", package: "ElevenLabsKit"),
            ],
            path: "Sources/OpenAEONKit",
            resources: [
                .process("Resources"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        .target(
            name: "OpenAEONChatUI",
            dependencies: [
                "OpenAEONKit",
                .product(
                    name: "Textual",
                    package: "textual",
                    condition: .when(platforms: [.macOS, .iOS])),
            ],
            path: "Sources/OpenAEONChatUI",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        .testTarget(
            name: "OpenAEONKitTests",
            dependencies: ["OpenAEONKit", "OpenAEONChatUI"],
            path: "Tests/OpenAEONKitTests",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .enableExperimentalFeature("SwiftTesting"),
            ]),
    ])
