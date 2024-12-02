// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Formic",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Formic",
            targets: ["Formic"]),
    ],
    dependencies: [
        .package(
              url: "https://github.com/apple/swift-argument-parser.git",
              .upToNextMajor(from: "1.5.0")),
        .package(
              url: "https://github.com/swiftlang/swift-format.git",
              .upToNextMajor(from: "600.0.0"))
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Formic",
            dependencies: [.product(name: "ArgumentParser", package: "swift-argument-parser")]
        ),
        .testTarget(
            name: "FormicTests",
            dependencies: ["Formic"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
