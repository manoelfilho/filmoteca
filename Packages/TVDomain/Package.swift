// swift-tools-version: 6.0
import PackageDescription

/// Domínio de TVs: modelos e interfaces (protocolos) para parear uma TV e abrir conteúdo nela.
///
/// Só usa frameworks do sistema (Foundation e Security, para o Keychain) e não conhece nenhuma marca.
/// As implementações (LG webOS e as próximas) dependem deste pacote.
let package = Package(
    name: "TVDomain",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "TVDomain", targets: ["TVDomain"]),
    ],
    targets: [
        .target(name: "TVDomain"),
        .testTarget(name: "TVDomainTests", dependencies: ["TVDomain"]),
    ]
)
