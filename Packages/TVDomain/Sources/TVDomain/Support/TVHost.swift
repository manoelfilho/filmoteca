import Foundation

public enum TVHost {
    /// Aceita "192.168.0.20", "tv-sala.local" ou o endereço colado com "http://" e porta.
    /// Devolve `nil` para endereços inválidos.
    public static func normalize(_ input: String) -> String? {
        var host = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if let url = URL(string: host), let scheme = url.scheme, ["http", "https", "ws", "wss"].contains(scheme) {
            host = url.host() ?? ""
        } else if let colon = host.lastIndex(of: ":"), host.filter({ $0 == ":" }).count == 1 {
            host = String(host[..<colon])
        }
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: ".-"))
        guard !host.isEmpty, host.unicodeScalars.allSatisfy(allowed.contains) else { return nil }
        return host
    }
}
