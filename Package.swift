// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "ComfyCalendar",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "ComfyCalendar",
            targets: ["ComfyCalendar"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ComfyCalendar",
            path: "Sources/ComfyCalendar"
        )
    ]
)
