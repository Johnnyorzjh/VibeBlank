// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "VibeBlank",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "VibeBlank", targets: ["VibeBlank"]),
        .executable(name: "VibeBlankCoreChecks", targets: ["VibeBlankCoreChecks"]),
        .library(name: "VibeBlankCore", targets: ["VibeBlankCore"])
    ],
    targets: [
        .target(
            name: "VibeBlankCore"
        ),
        .executableTarget(
            name: "VibeBlank",
            dependencies: ["VibeBlankCore"]
        ),
        .executableTarget(
            name: "VibeBlankCoreChecks",
            dependencies: ["VibeBlankCore"],
            path: "Checks/VibeBlankCoreChecks"
        )
    ]
)
