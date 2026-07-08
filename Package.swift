// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "CopyFolderPath",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "CopyFolderPathCore", targets: ["CopyFolderPathCore"]),
        .executable(name: "CopyFolderPath", targets: ["CopyFolderPath"]),
        .executable(name: "CopyFolderPathTests", targets: ["CopyFolderPathTests"])
    ],
    targets: [
        .target(
            name: "CopyFolderPathCore",
            path: "Sources/CopyFolderPathCore"
        ),
        .executableTarget(
            name: "CopyFolderPath",
            dependencies: ["CopyFolderPathCore"],
            path: "Sources/CopyFolderPath"
        ),
        .executableTarget(
            name: "CopyFolderPathTests",
            dependencies: ["CopyFolderPathCore"],
            path: "TestHarness/CopyFolderPathTests"
        )
    ]
)
