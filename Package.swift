// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "NavLibSwift",
    products: [
        .library(
            name: "NavLibSwift",
            targets: ["NavLib"]),
    ],
    targets: [
        .target(
            name: "NavLib",
            dependencies: ["NavLibCpp"],
            swiftSettings: [.interoperabilityMode(.Cxx)]
        ),
        .target(
            name: "NavLibCpp",
            publicHeadersPath: ".",
            swiftSettings: [.interoperabilityMode(.Cxx)]
        )
    ],
    cxxLanguageStandard: .cxx14
)
