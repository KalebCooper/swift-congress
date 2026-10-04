#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Immutable bill cosponsor page bounds, source modification window, and ordering.
public struct BillCosponsorQuery: Hashable, Sendable {
  /// Provider ordering by update time.
  public enum Sort: String, Hashable, Sendable {
    /// Earlier updates first.
    case updateDateAscending = "updateDate+asc"
    /// Later updates first.
    case updateDateDescending = "updateDate+desc"
  }

  /// Source lower timestamp bound, unparsed and passed through for source validation.
  public let fromDateTime: String?
  /// Initial page bounds.
  public let page: CongressQuery
  /// Explicit source sort, or nil to omit it.
  public let sort: Sort?
  /// Source upper timestamp bound, unparsed and passed through for source validation.
  public let toDateTime: String?

  /// Creates a query without interpreting dates or implying a stable snapshot.
  /// - Throws: `CongressInputError.invalidQuery` for invalid page bounds.
  public init(
    fromDateTime: String? = nil, limit: Int = 20, offset: Int = 0,
    sort: Sort? = nil, toDateTime: String? = nil
  ) throws(CongressInputError) {
    self.fromDateTime = fromDateTime
    page = try CongressQuery(limit: limit, offset: offset)
    self.sort = sort; self.toDateTime = toDateTime
  }

  func path(for identifier: BillSourceIdentifier) -> String {
    var c = URLComponents()
    c.path =
      "/v3/bill/\(identifier.congress)/\(identifier.type.rawValue)/\(identifier.number)/cosponsors"
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
}
