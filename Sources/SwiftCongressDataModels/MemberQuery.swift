#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Immutable member inventory filters; no claim of complete historical membership is made.
///
/// ```swift
/// let query = try MemberQuery(limit: 2, scope: .congress(117))
/// ```
public struct MemberQuery: Hashable, Sendable {
  /// The inventory route to browse.
  public enum Scope: Hashable, Sendable {
    /// The provider's unscoped member inventory at `/v3/member`.
    case all
    /// The members of one U.S. Congress at `/v3/member/congress/{n}`.
    case congress(Int)
  }

  /// The provider's `currentMember` filter, or nil to omit the parameter.
  ///
  /// The initializer defaults to `false`, which asks the source for its historical listing.
  /// Neither value promises complete membership; counts are the provider's.
  public let currentMember: Bool?
  /// The provider's inclusive lower modification timestamp, as supplied.
  public let fromDateTime: String?
  /// Page bounds.
  public let page: CongressQuery
  /// The inventory route.
  public let scope: Scope
  /// The provider's upper modification timestamp, as supplied.
  public let toDateTime: String?

  var path: String {
    var c = URLComponents()
    switch scope {
    case .all: c.path = "/v3/member"
    case .congress(let congress): c.path = "/v3/member/congress/\(congress)"
    }
    c.queryItems = []
    if let currentMember {
      c.queryItems?.append(.init(name: "currentMember", value: String(currentMember)))
    }
    c.queryItems?.append(.init(name: "format", value: "json"))
    if let fromDateTime { c.queryItems?.append(.init(name: "fromDateTime", value: fromDateTime)) }
    c.queryItems?.append(.init(name: "limit", value: String(page.limit)))
    c.queryItems?.append(.init(name: "offset", value: String(page.offset)))
    if let toDateTime { c.queryItems?.append(.init(name: "toDateTime", value: toDateTime)) }
    // Plus is encoded because the source interprets form-style query values.
    return c.percentEncodedPath + "?"
      + (c.percentEncodedQuery ?? "").split(separator: "+", omittingEmptySubsequences: false)
      .joined(separator: "%2B")
  }

  /// Creates a member query. Timestamp strings are preserved for source-side validation.
  ///
  /// Modification timestamps apply only to the unscoped inventory; the Congress route does not
  /// accept them.
  /// - Parameters:
  ///   - currentMember: The `currentMember` filter; nil omits it and `false` is the default.
  ///   - fromDateTime: The lower modification bound, passed through unchanged.
  ///   - limit: The page size, from 1 through 250.
  ///   - offset: The nonnegative initial offset.
  ///   - scope: The unscoped inventory or one positive Congress.
  ///   - toDateTime: The upper modification bound, passed through unchanged.
  /// - Throws: `CongressInputError.invalidQuery` for a nonpositive Congress, invalid pagination
  ///   bounds, or a modification bound combined with a Congress scope.
  public init(
    currentMember: Bool? = false, fromDateTime: String? = nil, limit: Int = 20,
    offset: Int = 0, scope: Scope = .all, toDateTime: String? = nil
  ) throws(CongressInputError) {
    if case .congress(let congress) = scope {
      guard congress > 0, fromDateTime == nil, toDateTime == nil else { throw .invalidQuery }
    }
    self.currentMember = currentMember; self.fromDateTime = fromDateTime
    page = try CongressQuery(limit: limit, offset: offset)
    self.scope = scope; self.toDateTime = toDateTime
  }
}
