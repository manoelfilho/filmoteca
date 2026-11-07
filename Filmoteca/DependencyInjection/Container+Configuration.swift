import FactoryKit
import Foundation

/// Dependências de configuração do app.
///
/// `AppConfiguration` lê o Info.plist uma única vez e é compartilhada por todo o app,
/// por isso fica registrada como `.singleton`.
extension Container {
    var appConfiguration: Factory<AppConfiguration> {
        self { AppConfiguration() }
            .singleton
    }

    var tmdbConfiguration: Factory<APIConfiguration> {
        self { self.appConfiguration().tmdb }
    }

    var streamingAvailabilityConfiguration: Factory<APIConfiguration> {
        self { self.appConfiguration().streamingAvailability }
    }

    /// Idioma do conteúdo pedido às APIs de dados, o mesmo da interface do app.
    ///
    /// O `Bundle` escolhe, entre as localizações do app (pt-BR e en), a que melhor
    /// atende às preferências do usuário. O código é convertido para o formato do TMDB.
    var contentLanguage: Factory<String> {
        self {
            let preferred = Bundle.main.preferredLocalizations.first ?? "en"
            return preferred.hasPrefix("pt") ? "pt-BR" : "en-US"
        }
        .singleton
    }
}
