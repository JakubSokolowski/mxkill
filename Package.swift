// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "mxkill",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "mxkill", targets: ["mxkill"]),
        .executable(name: "mxkillUnitTests", targets: ["mxkillUnitTests"])
    ],
    targets: [
        .target(
            name: "mxkillCore"
        ),
        .executableTarget(
            name: "mxkill",
            dependencies: ["mxkillCore"]
        ),
        .executableTarget(
            name: "mxkillUnitTests",
            dependencies: ["mxkillCore"]
        )
    ]
)
