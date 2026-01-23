// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WdkSwiftCore",
    platforms: [
        .iOS(.v14),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "WdkSwiftCore",
            targets: ["WdkSwiftCore"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/holepunchto/bare-kit-swift", branch: "main")
    ],
    targets: [
        .target(
            name: "WdkSwiftCore",
            dependencies: [
                .product(name: "BareKit", package: "bare-kit-swift")
            ]
        )
    ]
)
