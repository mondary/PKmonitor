// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "PKMonitor",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "PKMonitor", targets: ["PKMonitor"])],
    targets: [.executableTarget(name: "PKMonitor")],
    swiftLanguageModes: [.v5]
)
