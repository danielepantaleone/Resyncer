// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Resyncer",
    platforms: [
        .iOS(.v12),
        .macOS(.v12)
    ],
    products: [
        .library(name: "Resyncer", targets: ["Resyncer"])
    ],
    dependencies: [
        .package(url: "https://github.com/realm/SwiftLint.git", from: "0.58.2")
    ],
    targets: [
        .target(
            name: "Resyncer",
            dependencies: [],
            plugins: [
                .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint")
            ]
         ),
        .testTarget(
            name: "ResyncerTests",
            dependencies: [
                "Resyncer"
            ]
        )
    ]
)
