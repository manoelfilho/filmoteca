public struct PaginatedResult<Item: Sendable>: Sendable {
    public let items: [Item]
    /// Página atual, começando em 1.
    public let page: Int
    public let totalPages: Int
    public let totalResults: Int

    public init(items: [Item], page: Int, totalPages: Int, totalResults: Int) {
        self.items = items
        self.page = page
        self.totalPages = totalPages
        self.totalResults = totalResults
    }

    public var hasNextPage: Bool { page < totalPages }
    public var nextPage: Int? { hasNextPage ? page + 1 : nil }

    public static var empty: PaginatedResult<Item> {
        PaginatedResult(items: [], page: 1, totalPages: 0, totalResults: 0)
    }
}

extension PaginatedResult: Equatable where Item: Equatable {}
extension PaginatedResult: Hashable where Item: Hashable {}
