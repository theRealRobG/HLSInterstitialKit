// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HLSInterstitialKit",
    platforms: [.iOS(.v13), .tvOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "HLSInterstitialKit",
            targets: ["HLSInterstitialKit"]
        ),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(
            url: "https://github.com/comcast/mamba.git",
            .upToNextMinor(from: Version(1, 6, 0))
        ),
        .package(
            url: "https://github.com/theRealRobG/SCTE35Parser.git",
            .upToNextMinor(from: Version(0, 3, 1))
        )
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "HLSInterstitialKit",
            dependencies: ["mamba", "SCTE35Parser"]
        ),
        .testTarget(
            name: "HLSInterstitialKitTests",
            dependencies: ["HLSInterstitialKit"]
        ),
    ]
)
