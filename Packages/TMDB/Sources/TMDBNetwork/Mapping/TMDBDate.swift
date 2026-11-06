import Foundation

/// Datas do TMDB: `release_date` vem como `yyyy-MM-dd` (às vezes vazia)
/// e `published_at` dos vídeos vem como ISO 8601 completo.
enum TMDBDate {
    private static let dayFormat = Date.ISO8601FormatStyle(timeZone: .gmt).year().month().day()
    private static let dateTimeFormat = Date.ISO8601FormatStyle(timeZone: .gmt)

    static func day(from string: String?) -> Date? {
        guard let string, !string.isEmpty else { return nil }
        return try? dayFormat.parse(string)
    }

    static func dateTime(from string: String?) -> Date? {
        guard let string, !string.isEmpty else { return nil }
        return (try? dateTimeFormat.parse(string)) ?? day(from: String(string.prefix(10)))
    }

    static func string(from date: Date) -> String {
        dayFormat.format(date)
    }
}
