// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MarkSee",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(url: "https://github.com/gonzalezreal/textual", revision: "5b06b811c0f5313b6b84bbef98c635a630638c38"),
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
