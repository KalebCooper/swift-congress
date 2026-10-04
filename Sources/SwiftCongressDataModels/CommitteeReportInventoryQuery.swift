#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Standalone report inventory bounds, optional conference filter and source date window.
public struct CommitteeReportInventoryQuery: Hashable, Sendable {
  /// The three documented inventory route scopes.
  public enum Scope: Hashable, Sendable {
    /// Reports across the provider's available Congresses.
    case all
    /// Reports from one positive Congress.
    case congress(Int)
    /// Reports of an open, safe type from one positive Congress.
    case type(congress: Int, type: CommitteeReportType)
  }
  /// Nil omits the source filter; true and false send explicit source values.
  public let conference: Bool?
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
    case .all: c.path = "/v3/committee-report"
    case .congress(let congress): c.path = "/v3/committee-report/\(congress)"
    case .type(let congress, let type):
      c.path = "/v3/committee-report/\(congress)/\(type.rawValue)"
    }
    c.queryItems = []
    if let conference { c.queryItems?.append(.init(name: "conference", value: String(conference))) }
    c.queryItems?.append(.init(name: "format", value: "json"))
    if let fromDateTime { c.queryItems?.append(.init(name: "fromDateTime", value: fromDateTime)) }
    c.queryItems?.append(.init(name: "limit", value: String(page.limit)))
    c.queryItems?.append(.init(name: "offset", value: String(page.offset)))
    if let toDateTime { c.queryItems?.append(.init(name: "toDateTime", value: toDateTime)) }
    return c.percentEncodedPath + "?"
      + (c.percentEncodedQuery ?? "").split(separator: "+", omittingEmptySubsequences: false)
      .joined(separator: "%2B")
  }

  /// Validates route components and page bounds without asserting conference-filter semantics.
  /// - Throws: `CongressInputError.invalidQuery` for invalid scope or page bounds.
  public init(
    conference: Bool? = nil, fromDateTime: String? = nil, limit: Int = 20, offset: Int = 0,
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
    self.conference = conference
    self.fromDateTime = fromDateTime
    page = try CongressQuery(limit: limit, offset: offset)
    self.toDateTime = toDateTime
  }
}
