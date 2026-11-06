import Foundation
import Observation
import UIKit

/// Perfil exibido no topo da Home: nome e foto escolhidos pelo usuário.
///
/// O iOS não expõe a foto nem o nome do dono do iPhone (nem do ID Apple) aos apps,
/// então o perfil é preenchido pelo próprio usuário e fica salvo só no aparelho.
@Observable
final class TMDBUserProfile {
    var name: String {
        didSet { defaults.set(name, forKey: Self.nameKey) }
    }

    private(set) var photo: UIImage?

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let photoURL: URL

    private static let nameKey = "profile.name"
    /// Lado máximo da foto salva: suficiente para o avatar, leve no disco.
    nonisolated private static let photoSide: CGFloat = 512

    init(defaults: UserDefaults = .standard, photoURL: URL = TMDBUserProfile.defaultPhotoURL) {
        self.defaults = defaults
        self.photoURL = photoURL
        self.name = defaults.string(forKey: Self.nameKey) ?? ""
        self.photo = (try? Data(contentsOf: photoURL)).flatMap(UIImage.init(data:))
    }

    /// Nome sem espaços nas pontas; vazio quando o usuário ainda não preencheu.
    var displayName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// Iniciais para o avatar sem foto (ex.: "Maria Souza" → "MS").
    var initials: String {
        displayName
            .split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
            .map { String($0).uppercased() }
            .joined()
    }

    /// Reduz e salva a foto escolhida. `nil` remove a foto.
    func setPhoto(_ data: Data?) async {
        guard let data else {
            photo = nil
            try? FileManager.default.removeItem(at: photoURL)
            return
        }

        guard let jpeg = await Task.detached(operation: { Self.thumbnailJPEG(from: data) }).value,
              let image = UIImage(data: jpeg)
        else { return }

        photo = image
        try? FileManager.default.createDirectory(
            at: photoURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try? jpeg.write(to: photoURL, options: [.atomic, .completeFileProtection])
    }

    nonisolated private static func thumbnailJPEG(from data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let scale = min(1, photoSide / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        return image.preparingThumbnail(of: size)?.jpegData(compressionQuality: 0.85)
    }

    nonisolated static var defaultPhotoURL: URL {
        URL.applicationSupportDirectory.appending(path: "profile-photo.jpg")
    }
}
