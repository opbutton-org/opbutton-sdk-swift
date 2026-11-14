// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "OpButtonSDK",
    platforms: [.iOS(.v13), .macOS(.v10_15)],
    products: [.library(name: "OpButtonSDK", targets: ["OpButtonSDK"])],
    dependencies: [
        .package(url: "https://github.com/livekit/client-sdk-swift-xcframework.git", exact: "2.15.1")
    ],
    targets: [
        .target(
            name: "OpButtonSDK",
            dependencies: [.product(name: "LiveKit", package: "client-sdk-swift-xcframework")],
            path: "Sources/OpButtonSDK"
        ),
        .testTarget(name: "OpButtonSDKTests", dependencies: ["OpButtonSDK"])
    ],
    swiftLanguageVersions: [.v5]
)
