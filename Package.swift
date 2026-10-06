// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "PKMonitor",
    products: [.executable(name: "PKMonitor", targets: ["PKMonitor"])],
    dependencies: [.package(url: "https://github.com/sparkle-project/Sparkle", from: "2.7.0")],
    targets: [.executableTarget(
        name: "PKMonitor",
        dependencies: [.product(name: "Sparkle", package: "Sparkle")],
        path: "src/macos",
        exclude: ["Resources"]
    )],
    swiftLanguageModes: [.v5]
)
