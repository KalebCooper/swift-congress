/// Immutable law inventory scope and page bounds; no historical cutoff is imposed.
public struct LawQuery: Hashable, Sendable {
  /// The positive U.S. Congress number.
  public let congress: Int
  /// The initial page size and offset.
  public let page: CongressQuery
  /// A public or private category, or nil for the Congress's combined inventory.
  public let type: LawType?

  var path: String {
    "/v3/law/\(congress)" + (type.map { "/\($0.rawValue)" } ?? "")
      + "?format=json&limit=\(page.limit)&offset=\(page.offset)"
  }

  /// Creates a law inventory query using only the route's supported controls.
  /// - Parameters:
  ///   - congress: A positive Congress number.
  ///   - limit: A page size from 1 through 250; defaults to 20.
  ///   - offset: A nonnegative starting offset; defaults to zero.
  ///   - type: An optional public or private law category.
  /// - Throws: `CongressInputError.invalidQuery` for an invalid Congress or pagination bounds.
  public init(congress: Int, limit: Int = 20, offset: Int = 0, type: LawType? = nil)
    throws(CongressInputError)
  {
    guard congress > 0 else { throw .invalidQuery }
    self.congress = congress
    page = try CongressQuery(limit: limit, offset: offset)
    self.type = type
  }
}
