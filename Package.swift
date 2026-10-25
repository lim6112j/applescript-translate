// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PreviewTranslate",
    platforms: [.macOS("27.0")],
    products: [
        .executable(name: "PreviewTranslate", targets: ["PreviewTranslate"]),
        .library(name: "PreviewTranslateCore", targets: ["PreviewTranslateCore"]),
    ],
    targets: [
        .target(
            name: "PreviewTranslateCore",
            linkerSettings: [.linkedFramework("NaturalLanguage")]
        ),
        .executableTarget(
            name: "PreviewTranslate",
            dependencies: ["PreviewTranslateCore"],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("ApplicationServices"),
                .linkedFramework("PDFKit"),
                .linkedFramework("Translation"),
                .linkedFramework("Carbon"),
            ]
        ),
        .testTarget(
            name: "PreviewTranslateCoreTests",
            dependencies: ["PreviewTranslateCore"]
        ),
    ],
    swiftLanguageModes: [.v5]
)
