// swift-tools-version: 6.0
import PackageDescription

/// Provedor de dados Watchmode: onde cada filme está disponível e os links para abri-lo.
///
/// Implementa as interfaces de `MovieDomain` usando a rede de `NetworkCore`.
let package = Package(
    name: "Watchmode",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        /// Implementação das interfaces de `MovieDomain` usando a API do Watchmode.
        .library(name: "WatchmodeNetwork", targets: ["WatchmodeNetwork"]),
    ],
    dependencies: [
        .package(path: "../MovieDomain"),
        .package(path: "../NetworkCore"),
    ],
    targets: [
        .target(
            name: "WatchmodeNetwork",
            dependencies: [
                .product(name: "MovieDomain", package: "MovieDomain"),
                .product(name: "NetworkCore", package: "NetworkCore"),
            ]
        ),
        .testTarget(
            name: "WatchmodeNetworkTests",
            dependencies: [
                "WatchmodeNetwork",
                .product(name: "MovieDomain", package: "MovieDomain"),
                .product(name: "NetworkCore", package: "NetworkCore"),
            ]
        ),
    ]
)
