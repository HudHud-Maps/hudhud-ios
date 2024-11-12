// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TokensEnumGenerator",
    products: [
        .plugin(name: "TokensEnumGeneratorPlugin", targets: ["TokensEnumGeneratorPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/stencilproject/Stencil.git", from: "0.14.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0")
    ],
    targets: [
        .executableTarget(
            name: "TokensEnumGenerator",
            dependencies: [
                "Stencil",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .plugin(
            name: "TokensEnumGeneratorPlugin",
            capability: .buildTool(),
            dependencies: ["TokensEnumGenerator"]
        ),
        .testTarget(
            name: "TokensEnumGeneratorTests",
            dependencies: ["TokensEnumGenerator"]
        )
    ]
)
