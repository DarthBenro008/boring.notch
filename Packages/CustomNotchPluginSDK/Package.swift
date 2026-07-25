// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CustomNotchPluginSDK",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "CustomNotchPluginSDK", targets: ["CustomNotchPluginSDK"])
    ],
    targets: [
        .target(name: "CustomNotchPluginSDK"),
        .testTarget(
            name: "CustomNotchPluginSDKTests",
            dependencies: ["CustomNotchPluginSDK"]
        )
    ]
)
