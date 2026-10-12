// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BabyLock",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "BabyLock",
            path: "Sources/BabyLock",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("IOKit"),
                .linkedFramework("ApplicationServices"),
                .linkedFramework("Carbon"),
            ]
        )
    ]
)