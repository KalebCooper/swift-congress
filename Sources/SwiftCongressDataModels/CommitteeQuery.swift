#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Immutable committee directory scope, page bounds and source modification window.
public struct CommitteeQuery: Hashable, Sendable {
  /// Supported directory routes.
  public enum Scope: Hashable, Sendable {
    /// All published committees.
    case all
    /// Committees in one request chamber.
    case chamber(CommitteeChamber)
    /// Committees associated with one positive Congress number.
    case congress(Int)
    /// Committees in one chamber and positive Congress number.
    case congressChamber(chamber: CommitteeChamber, congress: Int)
  }

  /// Unparsed source lower timestamp bound.
  public let fromDateTime: String?
  /// Initial page bounds.
  public let page: CongressQuery
  /// The explicit directory scope.
  public let scope: Scope
  /// Unparsed source upper timestamp bound.
  public let toDateTime: String?

  /// Creates a query without interpreting source dates or implying a stable snapshot.
  /// - Throws: `CongressInputError.invalidQuery` for invalid Congress or page bounds.
  public init(
    fromDateTime: String? = nil, limit: Int = 20, offset: Int = 0,
    scope: Scope = .all, toDateTime: String? = nil
  ) throws(CongressInputError) {
    switch scope {
    case .congress(let congress), .congressChamber(_, let congress):
      guard congress > 0 else { throw .invalidQuery }
    case .all, .chamber: break
    }
    self.fromDateTime = fromDateTime
    page = try CongressQuery(limit: limit, offset: offset)
    self.scope = scope
    self.toDateTime = toDateTime
  }

  func path() -> String {
    var c = URLComponents()
    c.path = "/v3/committee"
    switch scope {
    case .all: break
    case .chamber(let chamber): c.path += "/\(chamber.rawValue)"
    case .congress(let congress): c.path += "/\(congress)"
    case .congressChamber(let chamber, let congress):
      c.path += "/\(congress)/\(chamber.rawValue)"
    }
    c.queryItems = [URLQueryItem(name: "format", value: "json")]
    if let fromDateTime { c.queryItems?.append(.init(name: "fromDateTime", value: fromDateTime)) }
    c.queryItems?.append(.init(name: "limit", value: String(page.limit)))
    c.queryItems?.append(.init(name: "offset", value: String(page.offset)))
    if let toDateTime { c.queryItems?.append(.init(name: "toDateTime", value: toDateTime)) }
    return c.percentEncodedPath + "?"
      + (c.percentEncodedQuery ?? "").split(separator: "+", omittingEmptySubsequences: false)
      .joined(separator: "%2B")
  }
}
