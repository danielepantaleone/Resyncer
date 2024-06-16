// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Resyncer",
    platforms: [
        .iOS(.v12),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "Resyncer",
            targets: ["Resyncer"])
    ],
    targets: [
        .target(
            name: "Resyncer",
            dependencies: [],
            resources: [.copy("PrivacyInfo.xcprivacy")]),
        .testTarget(
            name: "ResyncerTests",
            dependencies: ["Resyncer"])
    ]
)
