// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MiniMate1Client",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "MiniMate1Client",
            path: "Sources"
        ),
    ]
)
