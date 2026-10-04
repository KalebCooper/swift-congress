#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Amendment inventory bounds and source date windows across three route scopes.
public struct AmendmentQuery: Hashable, Sendable {
  /// The three documented inventory route scopes.
  public enum Scope: Hashable, Sendable {
    /// Amendments across the provider's available Congresses.
    case all
    /// Amendments from one positive Congress.
    case congress(Int)
    /// Amendments of an open, safe type from one positive Congress.
    case type(congress: Int, type: AmendmentType)
  }
  /// Source lower timestamp bound, passed through without date interpretation.
  public let fromDateTime: String?
  /// Validated initial page bounds.
  public let page: CongressQuery
  /// Validated scope with a lowercase request type where present.
  public let scope: Scope
  /// Source upper timestamp bound, passed through without date interpretation.
  public let toDateTime: String?

  var path: String {
    var c = URLComponents()
    switch scope {
    case .all: c.path = "/v3/amendment"
    case .congress(let congress): c.path = "/v3/amendment/\(congress)"
    case .type(let congress, let type):
      c.path = "/v3/amendment/\(congress)/\(type.rawValue)"
    }
    c.queryItems = []
    c.queryItems?.append(.init(name: "format", value: "json"))
    if let fromDateTime { c.queryItems?.append(.init(name: "fromDateTime", value: fromDateTime)) }
    c.queryItems?.append(.init(name: "limit", value: String(page.limit)))
    c.queryItems?.append(.init(name: "offset", value: String(page.offset)))
    if let toDateTime { c.queryItems?.append(.init(name: "toDateTime", value: toDateTime)) }
    return c.percentEncodedPath + "?"
      + (c.percentEncodedQuery ?? "").split(separator: "+", omittingEmptySubsequences: false)
      .joined(separator: "%2B")
  }

  /// Validates route and page bounds. Timestamp strings remain for source-side validation.
  /// - Throws: `CongressInputError.invalidQuery` for invalid scope or page bounds.
  public init(
    fromDateTime: String? = nil, limit: Int = 20, offset: Int = 0,
    scope: Scope = .all, toDateTime: String? = nil
  ) throws(CongressInputError) {
    switch scope {
    case .all: self.scope = .all
    case .congress(let congress):
      guard congress > 0 else { throw .invalidQuery }
      self.scope = scope
    case .type(let congress, let type):
      guard congress > 0, !type.rawValue.isEmpty,
        type.rawValue.utf8.allSatisfy({ (65...90).contains($0) || (97...122).contains($0) })
      else { throw .invalidQuery }
      self.scope = .type(congress: congress, type: .init(rawValue: type.rawValue.lowercased()))
    }
    self.fromDateTime = fromDateTime
    page = try CongressQuery(limit: limit, offset: offset)
    self.toDateTime = toDateTime
  }
}
