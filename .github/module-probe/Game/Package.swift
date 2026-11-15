// swift-tools-version: 6.0
import PackageDescription

// Stands in for a game package and for a host built outside Engine's package.
let package = Package(
    name: "Game",
    dependencies: [.package(path: "../Core")],
    targets: [
        .executableTarget(name: "Host", dependencies: [.product(name: "Core", package: "Core")]),
        .target(name: "Game", dependencies: [.product(name: "Core", package: "Core")]),
    ]
)
