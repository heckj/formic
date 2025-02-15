// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "updateExample",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        .package(path: "../.."), //.package(url: "https://github.com/heckj/formic.git", branch: "main"),
        // enough to support the following commands:
        // swift package format-source-code --allow-writing-to-package-directory
        // swift package lint-source-code
        .package(url: "https://github.com/swiftlang/swift-format.git",
            .upToNextMajor(from: "600.0.0")),
    ],
    targets: [
        .executableTarget(
            name: "updateExample",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Formic", package: "Formic"),
            ]
        ),
    ]
)
