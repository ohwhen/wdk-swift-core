// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "wdk-swift-core",
    platforms: [
        .iOS(.v14),
        .macOS(.v12)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "WdkSwiftCore",
            targets: ["WdkSwiftCore"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/holepunchto/bare-kit-swift", branch: "main")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "WdkSwiftCore",
            dependencies: [
                .product(name: "BareKit", package: "bare-kit-swift")
            ],
            exclude: ["../../WorkletSource", "../../Scripts"],
            
        ),
        .testTarget(
            name: "WdkSwiftCoreTests",
            dependencies: ["WdkSwiftCore"]
        ),
        
    ]
)
