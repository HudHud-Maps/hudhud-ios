// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BackendService",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "BackendService",
            targets: ["BackendService"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/SFSafeSymbols/SFSafeSymbols.git", from: "4.1.1"),
        .package(url: "https://github.com/apple/swift-openapi-generator", exact: "1.3.1"),
        .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.0.0"),
        .package(url: "https://github.com/salishseasoftware/LocationFormatter.git", from: "1.1.0"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "BackendService",
            dependencies: [
                .product(name: "SFSafeSymbols", package: "SFSafeSymbols"),
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "LocationFormatter", package: "locationformatter"),
                .product(name: "KeychainAccess", package: "KeychainAccess")
            ],
            plugins: [
                .plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator")
            ]
        )
    ]
)
