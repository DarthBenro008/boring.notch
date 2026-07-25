// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NotchPluginCore",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "NotchPluginCore", targets: ["NotchPluginCore"])
    ],
    targets: [
        .target(name: "NotchPluginCore"),
        .testTarget(
            name: "NotchPluginCoreTests",
            dependencies: ["NotchPluginCore"]
        )
    ]
)
