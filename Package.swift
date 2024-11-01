// swift-tools-version:5.6

import PackageDescription

let package = Package(
    name: "CameraBackground",
    platforms: [
        .iOS(.v11),
    ],
    products: [
        .library(name: "CameraBackground", targets: ["CameraBackground"]),
    ],
    dependencies: [
        .package(url: "https://github.com/yonat/SweeterSwift", from: "1.0.2"),
        .package(url: "https://github.com/yonat/MultiToggleButton", from: "1.8.2"),
    ],
    targets: [
        .target(name: "CameraBackground", dependencies: ["SweeterSwift", "MultiToggleButton"], path: "Sources", resources: [.process("PrivacyInfo.xcprivacy")]),
    ],
    swiftLanguageVersions: [.v5]
)
