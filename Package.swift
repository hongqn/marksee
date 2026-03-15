// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MarkSee",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(url: "https://github.com/gonzalezreal/textual", branch: "main"),
    ],
    targets: [
        .executableTarget(
            name: "MarkSee",
            dependencies: [
                .product(name: "Textual", package: "textual"),
            ],
            path: "Sources/MarkSee"
        )
    ]
)
