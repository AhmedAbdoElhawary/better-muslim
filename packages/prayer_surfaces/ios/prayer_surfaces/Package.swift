// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "prayer_surfaces",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        // flutter wants no underscore in a product name
        .library(name: "prayer-surfaces", targets: ["prayer_surfaces"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "prayer_surfaces",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
