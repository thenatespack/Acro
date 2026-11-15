// swift-tools-version: 6.0
import PackageDescription

// Stands in for Engine: a library in a dynamic product, plus a host in the same package.
let package = Package(
    name: "Core",
    products: [
        .library(name: "Core", type: .dynamic, targets: ["Core"]),
        .executable(name: "InHost", targets: ["InHost"]),
    ],
    targets: [
        .target(name: "Core"),
        .executableTarget(name: "InHost", dependencies: ["Core"]),
    ]
)
