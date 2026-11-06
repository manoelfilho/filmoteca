// swift-tools-version: 6.0
import PackageDescription

/// Controle de TVs LG (webOS) pela rede local.
///
/// Implementa as interfaces de `TVDomain` falando o protocolo SSAP da TV por WebSocket
/// (o mesmo usado por apps de controle remoto e pelo Home Assistant). Não é uma API
/// oficial da LG: a TV pede confirmação na tela no primeiro pareamento.
let package = Package(
    name: "LGWebOS",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "LGWebOS", targets: ["LGWebOS"]),
    ],
    dependencies: [
        .package(path: "../TVDomain"),
        .package(path: "../NetworkCore"),
    ],
    targets: [
        .target(
            name: "LGWebOS",
            dependencies: [
                .product(name: "TVDomain", package: "TVDomain"),
                .product(name: "NetworkCore", package: "NetworkCore"),
            ]
        ),
        .testTarget(
            name: "LGWebOSTests",
            dependencies: [
                "LGWebOS",
                .product(name: "TVDomain", package: "TVDomain"),
                .product(name: "NetworkCore", package: "NetworkCore"),
            ]
        ),
    ]
)
