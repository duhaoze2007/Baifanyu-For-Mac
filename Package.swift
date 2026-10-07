// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BaifanYu",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "BaifanYu",
            path: "Sources",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
