// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Persistence",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        /// Implementação local (SwiftData) das interfaces de favoritos de `MovieDomain`.
        .library(name: "MoviePersistence", targets: ["MoviePersistence"]),
    ],
    dependencies: [
        // Só o domínio: esta camada não conhece rede nem nenhuma API.
        .package(path: "../MovieDomain"),
    ],
    targets: [
        .target(
            name: "MoviePersistence",
            dependencies: [.product(name: "MovieDomain", package: "MovieDomain")]
        ),
        .testTarget(
            name: "MoviePersistenceTests",
            dependencies: ["MoviePersistence", .product(name: "MovieDomain", package: "MovieDomain")]
        ),
    ]
)
