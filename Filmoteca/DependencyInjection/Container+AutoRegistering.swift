import FactoryKit

/// Ponto central de configuração do container.
///
/// `autoRegister()` roda uma única vez, antes da primeira resolução de qualquer
/// dependência. Use para trocar implementações por contexto (previews, testes,
/// UI tests, ambientes) sem espalhar `#if` pelo código.
extension Container: @retroactive AutoRegistering {
    public func autoRegister() {
        // Exemplos de uso futuro:
        // movieService.onPreview { MockMovieService() }
        // movieService.onTest { MockMovieService() }
        // movieService.onArg("-mockAPI") { MockMovieService() }
    }
}
