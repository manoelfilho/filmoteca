// swift-tools-version: 6.0
import PackageDescription

/// Provedor de dados The Movie Database (TMDB).
///
/// Implementa as interfaces de `MovieDomain` usando a rede de `NetworkCore`.
let package = Package(
    name: "TMDB",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        /// Implementação das interfaces de `MovieDomain` usando a API do TMDB.
        .library(name: "TMDBNetwork", targets: ["TMDBNetwork"]),
    ],
    dependencies: [
        .package(path: "../MovieDomain"),
        .package(path: "../NetworkCore"),
    ],
    targets: [
        .target(
            name: "TMDBNetwork",
            dependencies: [
                .product(name: "MovieDomain", package: "MovieDomain"),
                .product(name: "NetworkCore", package: "NetworkCore"),
            ]
        ),
        .testTarget(
            name: "TMDBNetworkTests",
            dependencies: [
                "TMDBNetwork",
                .product(name: "MovieDomain", package: "MovieDomain"),
                .product(name: "NetworkCore", package: "NetworkCore"),
            ]
        ),
    ]
)
