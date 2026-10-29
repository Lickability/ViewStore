// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let packageName = "ViewStore"

let package = Package(
    name: packageName,
    platforms: [.iOS(.v15)],
    products: [.library(name: packageName, targets: [packageName])],
    dependencies: [
        .package(
            url: "https://github.com/pointfreeco/swift-case-paths",
            .upToNextMajor(from: "1.10.0")
        )
    ],
    targets: [
        .target(name: packageName, dependencies: [
            .product(name: "CasePaths", package: "swift-case-paths")
        ], path: "Sources/Store")
    ]
)
