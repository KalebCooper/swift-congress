#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Immutable bill inventory filters; no minimum historical Congress is imposed.
public struct BillQuery: Hashable, Sendable {
  /// Provider ordering by modification time.
  public enum Sort: String, Hashable, Sendable {
    /// Earlier modifications first.
    case updateDateAscending = "updateDate+asc"
    /// Later modifications first.
    case updateDateDescending = "updateDate+desc"
  }

  /// A U.S. Congress, or nil for the provider's unscoped inventory.
  public let congress: Int?
  /// The provider's inclusive lower modification timestamp, as supplied.
  public let fromDateTime: String?
  /// Page bounds.
  public let page: CongressQuery
  /// Explicit provider sort, or nil for the provider's default.
  public let sort: Sort?
  /// The provider's upper modification timestamp, as supplied.
  public let toDateTime: String?

  var path: String {
    var c = URLComponents()
    c.path = "/v3/bill" + (congress.map { "/\($0)" } ?? "")
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

  /// Creates a bill query. Timestamp strings are preserved for source-side validation.
  /// - Throws: `CongressInputError.invalidQuery` for invalid Congress or pagination bounds.
  public init(
    congress: Int? = nil, fromDateTime: String? = nil, limit: Int = 20,
    offset: Int = 0, sort: Sort? = nil, toDateTime: String? = nil
  ) throws(CongressInputError) {
    guard congress == nil || (congress ?? 0) > 0 else { throw .invalidQuery }
    self.congress = congress; self.fromDateTime = fromDateTime
    page = try CongressQuery(limit: limit, offset: offset)
    self.sort = sort; self.toDateTime = toDateTime
  }
}
