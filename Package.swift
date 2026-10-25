// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PreviewTranslate",
    // The deployment target is what LaunchServices checks before launching the
    // bundle, so it must not exceed the oldest macOS we intend to run on.
    platforms: [.macOS("26.0")],
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
