// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "TonSwift",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(name: "TonSwift", targets: ["TonSwift"]),
    ],
    dependencies: [
        .package(url: "https://github.com/attaswift/BigInt", .exact("5.3.0")),
        .package(url: "https://github.com/jedisct1/swift-sodium", .exact("0.9.1"))
    ],
    targets: [
        .target(
            name: "TonSwift",
            dependencies: [
                .product(name: "BigInt", package: "BigInt"),
                .product(name: "Sodium", package: "swift-sodium"),
            ]),
        .testTarget(
            name: "TonSwiftTests",
            dependencies: [
                .byName(name: "TonSwift"),
                .product(name: "BigInt", package: "BigInt"),
            ]),
    ]
)
