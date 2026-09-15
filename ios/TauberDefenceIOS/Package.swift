// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "TauberDefenceIOS",
    platforms: [
        .iOS(.v18),
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "TauberDefenceCore",
            targets: ["TauberDefenceCore"]
        ),
    ],
    targets: [
        .target(name: "TauberDefenceCore"),
        .testTarget(
            name: "TauberDefenceCoreTests",
            dependencies: ["TauberDefenceCore"]
        ),
    ]
)
