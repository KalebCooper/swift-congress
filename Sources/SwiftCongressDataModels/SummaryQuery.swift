#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Immutable published-summary feed filters.
///
/// Omitted date bounds retain the provider's recent-day default. A Congress scope or exhausting
/// that default feed does not establish all-time coverage. Use a finite window for backfills.
public struct SummaryQuery: Hashable, Sendable {
  /// The feed route to browse.
  public enum Scope: Hashable, Sendable {
    /// All bill types and Congresses in the requested publication window.
    case all
    /// One bill type within one Congress.
    case billType(congress: Int, type: BillType)
    /// All bill types within one Congress.
    case congress(Int)
  }

  /// Provider ordering by update time.
  public enum Sort: String, Hashable, Sendable {
    /// Earlier updates first.
    case updateDateAscending = "updateDate+asc"
    /// Later updates first.
    case updateDateDescending = "updateDate+desc"
  }

  /// Source lower timestamp bound, unparsed.
  public let fromDateTime: String?
  /// Initial page bounds.
  public let page: CongressQuery
  /// The feed route.
  public let scope: Scope
  /// Explicit provider sort, or nil to omit it.
  public let sort: Sort?
  /// Source upper timestamp bound, unparsed.
  public let toDateTime: String?

  var path: String {
    var c = URLComponents()
    switch scope {
    case .all: c.path = "/v3/summaries"
    case .billType(let congress, let type):
      c.path = "/v3/summaries/\(congress)/\(type.rawValue.lowercased())"
    case .congress(let congress): c.path = "/v3/summaries/\(congress)"
    }
    c.queryItems = [URLQueryItem(name: "format", value: "json")]
    if let fromDateTime { c.queryItems?.append(.init(name: "fromDateTime", value: fromDateTime)) }
    c.queryItems?.append(.init(name: "limit", value: String(page.limit)))
    c.queryItems?.append(.init(name: "offset", value: String(page.offset)))
    if let sort { c.queryItems?.append(.init(name: "sort", value: sort.rawValue)) }
    if let toDateTime { c.queryItems?.append(.init(name: "toDateTime", value: toDateTime)) }
    // Plus is encoded because the source interprets form-style query values.
    return c.percentEncodedPath + "?"
      + (c.percentEncodedQuery ?? "").split(separator: "+", omittingEmptySubsequences: false)
      .joined(separator: "%2B")
  }

  /// Creates a feed query, preserving timestamp strings for source-side validation.
  /// - Throws: `CongressInputError.invalidQuery` for a nonpositive Congress or invalid page bounds.
  public init(
    fromDateTime: String? = nil, limit: Int = 20, offset: Int = 0,
    scope: Scope = .all, sort: Sort? = nil, toDateTime: String? = nil
  ) throws(CongressInputError) {
    switch scope {
    case .all: break
    case .billType(let congress, let type):
      guard congress > 0, !type.rawValue.isEmpty,
        type.rawValue.utf8.allSatisfy({ (65...90).contains($0) || (97...122).contains($0) })
      else { throw .invalidQuery }
    case .congress(let congress):
      guard congress > 0 else { throw .invalidQuery }
    }
    self.fromDateTime = fromDateTime
    page = try CongressQuery(limit: limit, offset: offset)
    self.scope = scope; self.sort = sort; self.toDateTime = toDateTime
  }
}
