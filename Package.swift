// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "NavLibSwift",
    products: [
        .library(
            name: "NavLibSwift",
            targets: ["NavLibSwift", "NavLib"]),
    ],
    targets: [
        .target(
            name: "NavLibSwift",
            dependencies: ["NavLib"],
            swiftSettings: [.interoperabilityMode(.Cxx)]
        ),
        .target(
            name: "NavLib",
            publicHeadersPath: ".",
            swiftSettings: [.interoperabilityMode(.Cxx)]
        )
    ],
    cxxLanguageStandard: .cxx14
)
