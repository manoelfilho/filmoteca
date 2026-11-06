// swift-tools-version: 6.0
import PackageDescription

/// Controle de TVs Samsung (Tizen) pela rede local.
///
/// Implementa as interfaces de `TVDomain` usando a API de controle remoto da TV
/// (WebSocket nas portas 8002/8001 e HTTP na 8001), a mesma usada por apps de
/// controle remoto e pelo Home Assistant. Não é uma API documentada pela Samsung:
/// a TV pede permissão na tela no primeiro pareamento.
let package = Package(
    name: "SamsungTizen",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SamsungTizen", targets: ["SamsungTizen"]),
    ],
    dependencies: [
        .package(path: "../TVDomain"),
        .package(path: "../NetworkCore"),
    ],
    targets: [
        .target(
            name: "SamsungTizen",
            dependencies: [
                .product(name: "TVDomain", package: "TVDomain"),
                .product(name: "NetworkCore", package: "NetworkCore"),
            ]
        ),
        .testTarget(
            name: "SamsungTizenTests",
            dependencies: [
                "SamsungTizen",
                .product(name: "TVDomain", package: "TVDomain"),
                .product(name: "NetworkCore", package: "NetworkCore"),
            ]
        ),
    ]
)
