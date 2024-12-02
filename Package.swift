// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "formic",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "formic",
            targets: ["formic"]),
    ],
    dependencies: [
        .package(
              url: "https://github.com/apple/swift-argument-parser.git",
              .upToNextMajor(from: "1.5.0")),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "formic",
            dependencies: [.product(name: "ArgumentParser", package: "swift-argument-parser")]
        ),
        .testTarget(
            name: "formicTests",
            dependencies: ["formic"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
