import FactoryKit
import MoviePersistence

/// Armazenamento local e implementações concretas de persistência.
///
/// Só este arquivo conhece o SwiftData (via `MoviePersistence`).
/// O resto do app usa as interfaces de favoritos registradas em `Container+Movies.swift`.
extension Container {
    var movieStore: Factory<SwiftDataMovieStore> {
        self {
            do {
                return try SwiftDataMovieStore.make()
            } catch {
                // Sem banco no disco, o app segue funcionando: os favoritos valem só nesta sessão.
                assertionFailure("Falha ao abrir o banco local: \(error)")
                return try! SwiftDataMovieStore.make(inMemory: true)
            }
        }
        .singleton
    }
}
