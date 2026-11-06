// swift-tools-version: 6.0
import PackageDescription

/// Camada de rede genérica: não conhece nenhum domínio (filmes, música…) nem nenhuma API.
/// Qualquer provedor de dados remoto (TMDB e os próximos) reaproveita este pacote.
let package = Package(
    name: "NetworkCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        /// Abstrações de HTTP (`HTTPClient`, com Alamofire) e WebSocket (`WebSocketClient`, com URLSession).
        .library(name: "NetworkCore", targets: ["NetworkCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.12.2"),
    ],
    targets: [
        .target(
            name: "NetworkCore",
            dependencies: [.product(name: "Alamofire", package: "Alamofire")]
        ),
    ]
)
