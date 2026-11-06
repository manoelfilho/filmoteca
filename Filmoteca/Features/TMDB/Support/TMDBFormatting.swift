import Foundation
import MovieDomain

// Formatação dos dados de filme para a interface, respeitando o idioma do usuário.

extension Movie {
    /// Ano de lançamento. As datas do TMDB são dias em UTC, então o ano é lido em UTC.
    var releaseYear: String? {
        guard let releaseDate else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return String(calendar.component(.year, from: releaseDate))
    }

    var releaseDateText: String? {
        releaseDate?.formatted(Date.FormatStyle(date: .long, time: .omitted, timeZone: .gmt))
    }

    /// Nota de 0 a 10 com uma casa decimal (ex.: "8,4").
    var ratingText: String {
        voteAverage.formatted(.number.precision(.fractionLength(1)))
    }

    /// Quantidade de votos compacta (ex.: "30 mil votos").
    var votesText: String {
        let count = voteCount.formatted(.number.notation(.compactName))
        return String(localized: "tmdb_movie_votes \(count)")
    }

    var originalLanguageName: String? {
        guard let originalLanguage else { return nil }
        return Locale.current.localizedString(forLanguageCode: originalLanguage)?
            .capitalized(with: .current)
    }
}

extension MovieDetails {
    /// Duração no formato local (ex.: "2 h 19 min").
    var runtimeText: String? {
        guard let runtime else { return nil }
        return Duration.seconds(runtime * 60)
            .formatted(.units(allowed: [.hours, .minutes], width: .abbreviated))
    }

    var genresText: String? {
        genres.isEmpty ? nil : genres.prefix(3).map(\.name).joined(separator: ", ")
    }

    var budgetText: String? { budget.map(Self.dollars) }
    var revenueText: String? { revenue.map(Self.dollars) }

    private static func dollars(_ value: Int) -> String {
        value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }
}

extension MovieStatus {
    var localizedName: String {
        switch self {
        case .rumored: String(localized: "tmdb_status_rumored")
        case .planned: String(localized: "tmdb_status_planned")
        case .inProduction: String(localized: "tmdb_status_in_production")
        case .postProduction: String(localized: "tmdb_status_post_production")
        case .released: String(localized: "tmdb_status_released")
        case .canceled: String(localized: "tmdb_status_canceled")
        case .unknown: String(localized: "tmdb_status_unknown")
        }
    }
}

extension DataSourceError {
    var localizedMessage: String {
        switch self {
        case .unauthorized: String(localized: "tmdb_error_unauthorized")
        case .connectivity, .timeout: String(localized: "tmdb_error_connectivity")
        case .storage: String(localized: "tmdb_error_storage")
        default: String(localized: "tmdb_error_generic")
        }
    }
}
