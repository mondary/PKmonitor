// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "PKMonitor",
    platforms: [.macOS(.v13)],
    dependencies: [.package(url: "https://github.com/sparkle-project/Sparkle", from: "2.7.0")],
    products: [.executable(name: "PKMonitor", targets: ["PKMonitor"])],
    targets: [.executableTarget(
        name: "PKMonitor",
        dependencies: [.product(name: "Sparkle", package: "Sparkle")],
        path: "src/macos",
        exclude: ["Resources"]
    )],
    swiftLanguageModes: [.v5]
)
