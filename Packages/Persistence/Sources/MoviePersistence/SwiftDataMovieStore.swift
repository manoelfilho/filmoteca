import Foundation
import MovieDomain
import SwiftData

/// Implementação das interfaces de favoritos com SwiftData.
///
/// É um `ModelActor`: todo acesso ao `ModelContext` acontece no executor do próprio
/// actor, fora da main thread, e o app só recebe `Movie` (valores `Sendable`).
@ModelActor
public actor SwiftDataMovieStore {
    /// Quem está observando a lista de favoritos (`observeFavoriteMovies`).
    private var observers: [UUID: AsyncStream<[Movie]>.Continuation] = [:]

    /// Cria o store com o banco no disco do app (ou só em memória, para testes e previews).
    public static func make(inMemory: Bool = false) throws -> SwiftDataMovieStore {
        let schema = Schema([FavoriteMovieEntity.self])
        let configuration = ModelConfiguration("MovieStore", schema: schema, isStoredInMemoryOnly: inMemory)
        do {
            let container = try ModelContainer(for: schema, configurations: configuration)
            return SwiftDataMovieStore(modelContainer: container)
        } catch {
            throw DataSourceError.storage(String(describing: error))
        }
    }

    // MARK: - Privado

    private func fetchFavorites() throws -> [Movie] {
        let descriptor = FetchDescriptor<FavoriteMovieEntity>(
            sortBy: [SortDescriptor(\.savedAt, order: .reverse)]
        )
        return try storageOperation { try modelContext.fetch(descriptor).map { $0.toDomain() } }
    }

    private func entity(id: MovieID) throws -> FavoriteMovieEntity? {
        let rawID = id.rawValue
        var descriptor = FetchDescriptor<FavoriteMovieEntity>(predicate: #Predicate { $0.movieID == rawID })
        descriptor.fetchLimit = 1
        return try storageOperation { try modelContext.fetch(descriptor).first }
    }

    private func saveAndNotify() throws {
        try storageOperation { try modelContext.save() }
        guard !observers.isEmpty, let movies = try? fetchFavorites() else { return }
        for observer in observers.values {
            observer.yield(movies)
        }
    }

    private func removeObserver(_ id: UUID) {
        observers[id] = nil
    }

    /// Converte erros do SwiftData no erro do domínio.
    private func storageOperation<T>(_ operation: () throws -> T) throws -> T {
        do {
            return try operation()
        } catch let error as DataSourceError {
            throw error
        } catch {
            throw DataSourceError.storage(String(describing: error))
        }
    }
}

// MARK: - Interfaces de MovieDomain

extension SwiftDataMovieStore: ListFavoriteMovies {
    public func listFavoriteMovies() throws -> [Movie] {
        try fetchFavorites()
    }
}

extension SwiftDataMovieStore: ObserveFavoriteMovies {
    public func observeFavoriteMovies() -> AsyncStream<[Movie]> {
        // Quem observa só precisa da lista mais recente.
        let (stream, continuation) = AsyncStream.makeStream(of: [Movie].self, bufferingPolicy: .bufferingNewest(1))
        let id = UUID()
        observers[id] = continuation
        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeObserver(id) }
        }
        if let movies = try? fetchFavorites() {
            continuation.yield(movies)
        }
        return stream
    }
}

extension SwiftDataMovieStore: SaveFavoriteMovie {
    public func saveFavoriteMovie(_ movie: Movie) throws {
        if let existing = try entity(id: movie.id) {
            existing.update(from: movie)
        } else {
            modelContext.insert(FavoriteMovieEntity(movie: movie, savedAt: .now))
        }
        try saveAndNotify()
    }
}

extension SwiftDataMovieStore: RemoveFavoriteMovie {
    public func removeFavoriteMovie(id: MovieID) throws {
        guard let existing = try entity(id: id) else { return }
        modelContext.delete(existing)
        try saveAndNotify()
    }
}

extension SwiftDataMovieStore: CheckFavoriteMovie {
    public func isFavoriteMovie(id: MovieID) throws -> Bool {
        try entity(id: id) != nil
    }
}
