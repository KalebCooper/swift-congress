#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Immutable committee bill page bounds and source modification window.
public struct CommitteeBillQuery: Hashable, Sendable {
  /// Source lower timestamp bound, unparsed and passed through for source validation.
  public let fromDateTime: String?
  /// Initial page bounds.
  public let page: CongressQuery
  /// Source upper timestamp bound, unparsed and passed through for source validation.
  public let toDateTime: String?

  /// Creates a query without interpreting dates or implying a stable snapshot.
  /// - Throws: `CongressInputError.invalidQuery` for invalid page bounds.
  public init(
    fromDateTime: String? = nil, limit: Int = 20, offset: Int = 0,
    toDateTime: String? = nil
  ) throws(CongressInputError) {
    self.fromDateTime = fromDateTime
    page = try CongressQuery(limit: limit, offset: offset)
    self.toDateTime = toDateTime
  }

  func path(for identifier: CommitteeIdentifier) -> String {
    var c = URLComponents()
    c.path = "/v3/committee/\(identifier.chamber.rawValue)/\(identifier.code)/bills"
    c.queryItems = [URLQueryItem(name: "format", value: "json")]
    if let fromDateTime { c.queryItems?.append(.init(name: "fromDateTime", value: fromDateTime)) }
    c.queryItems?.append(.init(name: "limit", value: String(page.limit)))
    c.queryItems?.append(.init(name: "offset", value: String(page.offset)))
    if let toDateTime { c.queryItems?.append(.init(name: "toDateTime", value: toDateTime)) }
    // Plus is encoded because the source interprets form-style query values.
    return c.percentEncodedPath + "?"
      + (c.percentEncodedQuery ?? "").split(separator: "+", omittingEmptySubsequences: false)
      .joined(separator: "%2B")
  }
}
