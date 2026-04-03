// swift-tools-version:6.3
import PackageDescription

let package = Package(
    name: "Logger",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "Logger",
            targets: ["Logger"]
        )
    ],
    targets: [
        .target(
            name: "Logger"
        )
    ]
)
