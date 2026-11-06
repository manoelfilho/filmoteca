// swift-tools-version: 6.0
import PackageDescription

/// Domínio de filmes: modelos e interfaces (protocolos).
///
/// Não depende de nada além da Foundation. As implementações (TMDB, Persistence…)
/// dependem deste pacote, nunca o contrário.
let package = Package(
    name: "MovieDomain",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "MovieDomain", targets: ["MovieDomain"]),
    ],
    targets: [
        .target(name: "MovieDomain"),
    ]
)
