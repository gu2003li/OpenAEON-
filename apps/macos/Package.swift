// swift-tools-version: 6.2
// Package manifest for the OpenAEON macOS companion (menu bar app + IPC library).

import PackageDescription

let package = Package(
    name: "OpenAEON",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(name: "OpenAEONIPC", targets: ["OpenAEONIPC"]),
        .library(name: "OpenAEONDiscovery", targets: ["OpenAEONDiscovery"]),
        .executable(name: "OpenAEON", targets: ["OpenAEON"]),
        .executable(name: "openaeon-mac", targets: ["OpenAEONMacCLI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/orchetect/MenuBarExtraAccess", exact: "1.2.2"),
        .package(url: "https://github.com/swiftlang/swift-subprocess.git", from: "0.1.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.8.0"),
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.8.1"),
        .package(url: "https://github.com/steipete/Peekaboo.git", branch: "main"),
        .package(path: "../shared/OpenAEONKit"),
        .package(path: "../../Swabble"),
    ],
    targets: [
        .target(
            name: "OpenAEONIPC",
            dependencies: [],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        .target(
            name: "OpenAEONDiscovery",
            dependencies: [
                .product(name: "OpenAEONKit", package: "OpenAEONKit"),
            ],
            path: "Sources/OpenAEONDiscovery",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        .executableTarget(
            name: "OpenAEON",
            dependencies: [
                "OpenAEONIPC",
                "OpenAEONDiscovery",
                .product(name: "OpenAEONKit", package: "OpenAEONKit"),
                .product(name: "OpenAEONChatUI", package: "OpenAEONKit"),
                .product(name: "OpenAEONProtocol", package: "OpenAEONKit"),
                .product(name: "SwabbleKit", package: "swabble"),
                .product(name: "MenuBarExtraAccess", package: "MenuBarExtraAccess"),
                .product(name: "Subprocess", package: "swift-subprocess"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Sparkle", package: "Sparkle"),
                .product(name: "PeekabooBridge", package: "Peekaboo"),
                .product(name: "PeekabooAutomationKit", package: "Peekaboo"),
            ],
            exclude: [
                "Resources/Info.plist",
            ],
            resources: [
                .copy("Resources/OpenAEON.icns"),
                .copy("Resources/DeviceModels"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        .executableTarget(
            name: "OpenAEONMacCLI",
            dependencies: [
                "OpenAEONDiscovery",
                .product(name: "OpenAEONKit", package: "OpenAEONKit"),
                .product(name: "OpenAEONProtocol", package: "OpenAEONKit"),
            ],
            path: "Sources/OpenAEONMacCLI",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        .testTarget(
            name: "OpenAEONIPCTests",
            dependencies: [
                "OpenAEONIPC",
                "OpenAEON",
                "OpenAEONDiscovery",
                .product(name: "OpenAEONProtocol", package: "OpenAEONKit"),
                .product(name: "SwabbleKit", package: "swabble"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .enableExperimentalFeature("SwiftTesting"),
            ]),
    ])
