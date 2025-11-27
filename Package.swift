//swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AppleSignInLibrary",
    // Support both iOS and macOS. The SwiftGodot dependency requires macOS 14+,
    // so the package macOS deployment target is set accordingly.
    platforms: [.iOS(.v17), .macOS(.v14)],
    
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "AppleSignInLibrary",
            type: .dynamic,
            targets: ["AppleSignInLibrary"]),
    ],
    dependencies: [
            .package(url: "https://github.com/migueldeicaza/SwiftGodot", branch: "main")
        ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "AppleSignInLibrary",
            dependencies: [
                            "SwiftGodot",
                        ],
            swiftSettings: [.unsafeFlags(["-suppress-warnings"])]),

    ]
)
