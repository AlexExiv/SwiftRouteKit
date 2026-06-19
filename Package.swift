// swift-tools-version: 5.9

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "RouterSwiftUI",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "RouterSwiftUI",
            targets: ["RouterSwiftUI"]),
        .plugin(
            name: "RouterSwiftUIGeneratorPlugin",
            targets: ["RouterSwiftUIGeneratorPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0")
    ],
    targets: [
        .macro(
            name: "RouterSwiftUIMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ],
            path: "RouterSwiftUIMacros"),
        .target(
            name: "RouterSwiftUI",
            dependencies: ["RouterSwiftUIMacros"],
            path: "RouterSwiftUI"),
        .executableTarget(
            name: "RouterSwiftUIGenerator",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax")
            ],
            path: "RouterSwiftUIGenerator"),
        .plugin(
            name: "RouterSwiftUIGeneratorPlugin",
            capability: .buildTool(),
            dependencies: ["RouterSwiftUIGenerator"],
            path: "RouterSwiftUIGeneratorPlugin"),
        .target(
            name: "RouterSwiftUISample",
            dependencies: ["RouterSwiftUI"],
            path: "RouterSwiftUISample",
            plugins: ["RouterSwiftUIGeneratorPlugin"]),
        .testTarget(
            name: "RouterSwiftUITests",
            dependencies: ["RouterSwiftUI"],
            path: "RouterSwiftUITests",
            plugins: ["RouterSwiftUIGeneratorPlugin"])
    ]
)
