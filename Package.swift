// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "FeedbackKit",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "FeedbackKit",
            targets: ["FeedbackKit"]
        ),
    ],
    targets: [
        .target(
            name: "FeedbackKit",
            path: "Sources/FeedbackKit"
        ),
    ]
)
