import Foundation
import MovieDomain
import Observation

/// Estado da aba Busca.
///
/// Recebe só a interface `SearchMovies`: não sabe qual API responde à busca.
/// O idioma vem injetado (o mesmo da interface do app), então títulos e sinopses
/// voltam em pt-BR ou en conforme o usuário.
@Observable
final class TMDBSearchViewModel {
    enum State: Equatable {
        /// Campo vazio: nada buscado ainda.
        case idle
        /// Primeira busca de um termo, sem resultados anteriores na tela.
        case loading
        case loaded
        case failed(DataSourceError)
    }

    var query: String

    private(set) var state: State = .idle
    private(set) var results: [Movie] = []
    private(set) var totalResults = 0
    /// Uma busca está em andamento enquanto os resultados anteriores continuam visíveis.
    private(set) var isSearching = false
    private(set) var isLoadingNextPage = false

    /// Gênero escolhido no carrossel de tipos; `nil` mostra todos.
    ///
    /// A busca do TMDB não filtra por gênero, então o filtro vale para os resultados já carregados.
    var selectedGenreID: Genre.ID?

    /// O gênero escolhido, se algum resultado carregado for dele.
    var activeGenreID: Genre.ID? {
        guard let selectedGenreID, results.contains(where: { $0.genreIDs.contains(selectedGenreID) }) else { return nil }
        return selectedGenreID
    }

    var visibleResults: [Movie] { results.filtered(byGenre: activeGenreID) }

    var hasNextPage: Bool { nextPage != nil }

    /// Termo de busca sem espaços nas pontas.
    var searchText: String { query.trimmingCharacters(in: .whitespacesAndNewlines) }

    @ObservationIgnored private let searchMovies: any SearchMovies
    @ObservationIgnored private let language: String?
    @ObservationIgnored private let debounce: Duration
    /// Termo dos resultados exibidos; evita repetir a mesma busca.
    @ObservationIgnored private var loadedText: String?
    @ObservationIgnored private var nextPage: Int?

    init(
        searchMovies: any SearchMovies,
        language: String?,
        query: String = "",
        debounce: Duration = .milliseconds(400)
    ) {
        self.searchMovies = searchMovies
        self.language = language
        self.query = query
        self.debounce = debounce
    }

    /// Chamado a cada mudança do texto. Espera o usuário parar de digitar antes de buscar.
    ///
    /// A view chama este método com `.task(id: query)`: digitar de novo cancela a
    /// espera (ou a requisição) anterior, então só o termo mais recente chega à tela.
    func queryChanged() async {
        let text = searchText
        guard !text.isEmpty else {
            reset()
            return
        }
        guard text != loadedText else { return }

        try? await Task.sleep(for: debounce)
        guard !Task.isCancelled else { return }
        await search(text)
    }

    func retry() async {
        let text = searchText
        guard !text.isEmpty else { return }
        await search(text)
    }

    /// Carrega a próxima página do termo atual (rolagem infinita).
    func loadNextPage() async {
        guard !isLoadingNextPage, let page = nextPage, let text = loadedText else { return }

        isLoadingNextPage = true
        defer { isLoadingNextPage = false }

        guard let result = try? await searchMovies.searchMovies(makeQuery(text, page: page)),
              !Task.isCancelled,
              loadedText == text
        else { return }

        // Páginas do TMDB podem repetir filmes; mantém cada um uma vez só.
        let knownIDs = Set(results.map(\.id))
        results += result.items.filter { !knownIDs.contains($0.id) }
        nextPage = result.nextPage
        totalResults = result.totalResults
    }

    // MARK: - Privado

    private func search(_ text: String) async {
        if results.isEmpty { state = .loading }
        isSearching = true

        do {
            let result = try await searchMovies.searchMovies(makeQuery(text, page: 1))
            // Cancelada (novo termo ou saída da tela): a busca seguinte assume.
            guard !Task.isCancelled else { return }

            results = result.items
            totalResults = result.totalResults
            nextPage = result.nextPage
            loadedText = text
            state = .loaded
        } catch {
            guard !Task.isCancelled else { return }
            results = []
            totalResults = 0
            nextPage = nil
            loadedText = nil
            state = .failed(error as? DataSourceError ?? .unknown(String(describing: error)))
        }
        isSearching = false
    }

    private func makeQuery(_ text: String, page: Int) -> MovieSearchQuery {
        MovieSearchQuery(text: text, page: page, language: language)
    }

    private func reset() {
        state = .idle
        results = []
        totalResults = 0
        nextPage = nil
        loadedText = nil
        isSearching = false
    }
}
