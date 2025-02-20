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
        .package(
            url: "https://github.com/apple/swift-async-dns-resolver",
            .upToNextMajor(from: "0.1.0")
        ),
        // .package(url: "https://github.com/Zollerboy1/SwiftCommand.git", from: "1.4.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-parsing", from: "0.13.0"),
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.0.0"),
        .package(url: "https://github.com/swiftlang/swift-format.git",
            .upToNextMajor(from: "600.0.0")),
        //.package(url: "https://github.com/orlandos-nl/Citadel/", from: "0.9.0"),
        //.package(url: "https://github.com/apple/swift-crypto.git", "1.0.0" ..< "2.1.0"),
        .package(url: "https://github.com/neallester/swift-log-testing.git", from: "0.0.1"),
    ],
    targets: [
        .target(
            name: "Formic",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "AsyncDNSResolver", package: "swift-async-dns-resolver"),
                // .product(name: "SwiftCommand", package: "SwiftCommand"),
                .product(name: "Parsing", package: "swift-parsing"),
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "Logging", package: "swift-log"),
                //.product(name: "Citadel", package: "Citadel"),
                //.product(name: "Crypto", package: "swift-crypto"),
                //.product(name: "_CryptoExtras", package: "swift-crypto"),
            ]
        ),
        .testTarget(
            name: "FormicTests",
            dependencies: [
                "Formic",
                .product(name: "SwiftLogTesting", package: "swift-log-testing")
            ],
            resources: [
                .copy("formicTests/Fixtures/id_ed25519"),
                .copy("formicTests/Fixtures/id_ed25519.pub")
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
