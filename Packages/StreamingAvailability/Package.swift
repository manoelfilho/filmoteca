// swift-tools-version: 6.0
import PackageDescription

/// Provedor de dados Streaming Availability (Movie of the Night): onde cada filme está
/// disponível e os links para abri-lo.
///
/// Implementa as interfaces de `MovieDomain` usando a rede de `NetworkCore`.
let package = Package(
    name: "StreamingAvailability",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        /// Implementação das interfaces de `MovieDomain` usando a API Streaming Availability.
        .library(name: "StreamingAvailabilityNetwork", targets: ["StreamingAvailabilityNetwork"]),
    ],
    dependencies: [
        .package(path: "../MovieDomain"),
        .package(path: "../NetworkCore"),
    ],
    targets: [
        .target(
            name: "StreamingAvailabilityNetwork",
            dependencies: [
                .product(name: "MovieDomain", package: "MovieDomain"),
                .product(name: "NetworkCore", package: "NetworkCore"),
            ]
        ),
        .testTarget(
            name: "StreamingAvailabilityNetworkTests",
            dependencies: [
                "StreamingAvailabilityNetwork",
                .product(name: "MovieDomain", package: "MovieDomain"),
                .product(name: "NetworkCore", package: "NetworkCore"),
            ]
        ),
    ]
)
