// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "TonSwift",
    products: [
        .library(name: "TonSwift", targets: ["TonSwift"]),
    ],
    dependencies: [
        .package(url: "https://github.com/attaswift/BigInt", exact: "5.3.0")
    ],
    targets: [
        .target(
            name: "TonSwift",
            dependencies: [
                .product(name: "BigInt", package: "BigInt"),
            ]),
        .testTarget(
            name: "TonSwiftTests",
            dependencies: [
                .byName(name: "TonSwift"),
                .product(name: "BigInt", package: "BigInt"),
            ]),
    ]
)
