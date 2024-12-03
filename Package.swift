// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Formic",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [
        .library(
            name: "Formic",
            targets: ["Formic"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-argument-parser.git",
            .upToNextMajor(from: "1.5.0")),
        .package(url: "https://github.com/Zollerboy1/SwiftCommand.git", from: "1.4.0"),
        .package(url: "https://github.com/pointfreeco/swift-parsing", from: "0.13.0"),
        .package(url: "https://github.com/swiftlang/swift-format.git",
            .upToNextMajor(from: "600.0.0"))
    ],
    targets: [
        .target(
            name: "Formic",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SwiftCommand", package: "SwiftCommand"),
                .product(name: "Parsing", package: "swift-parsing")
            ]
        ),
        .testTarget(
            name: "FormicTests",
            dependencies: [
                "Formic"
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
