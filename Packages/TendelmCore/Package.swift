// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "TendelmCore",
    defaultLocalization: "en",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "TendelmCore", targets: ["TendelmCore"])
    ],
    targets: [
        .target(
            name: "TendelmCore",
            resources: [.process("Resources")]
        )
    ]
)
