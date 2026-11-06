public struct MovieCredits: Hashable, Sendable {
    public let movieID: MovieID
    public let cast: [CastMember]
    public let crew: [CrewMember]

    public init(movieID: MovieID, cast: [CastMember] = [], crew: [CrewMember] = []) {
        self.movieID = movieID
        self.cast = cast
        self.crew = crew
    }

    public var directors: [CrewMember] { crew.filter { $0.job == "Director" } }
}

public struct CastMember: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let character: String
    public let profile: RemoteImage?
    /// Posição nos créditos (0 = principal).
    public let order: Int

    public init(id: String, name: String, character: String, profile: RemoteImage? = nil, order: Int = 0) {
        self.id = id
        self.name = name
        self.character = character
        self.profile = profile
        self.order = order
    }
}

public struct CrewMember: Identifiable, Hashable, Sendable {
    /// Uma mesma pessoa pode ter várias funções; o id combina pessoa e função.
    public let id: String
    public let personID: String
    public let name: String
    public let job: String
    public let department: String
    public let profile: RemoteImage?

    public init(id: String, personID: String, name: String, job: String, department: String, profile: RemoteImage? = nil) {
        self.id = id
        self.personID = personID
        self.name = name
        self.job = job
        self.department = department
        self.profile = profile
    }
}
