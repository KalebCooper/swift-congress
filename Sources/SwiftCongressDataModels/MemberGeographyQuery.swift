#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Immutable geographic member filters using each route's supported controls.
///
/// ```swift
/// let query = try MemberGeographyQuery(scope: .state(limit: 20, stateCode: "AK"))
/// ```
/// District results may include members whose published district changed after redistricting.
/// The query describes a provider inventory, not membership on a particular date.
public struct MemberGeographyQuery: Hashable, Sendable {
  /// The geographic inventory route and its supported page-size control.
  public enum Scope: Hashable, Sendable {
    /// Members for a positive Congress, nonnegative district, and two-letter state or territory.
    case congressDistrict(congress: Int, district: Int, stateCode: String)
    /// Members for a nonnegative district and two-letter state or territory.
    case district(district: Int, stateCode: String)
    /// Members for a two-letter state or territory, optionally requesting 1 through 250 records.
    case state(limit: Int? = nil, stateCode: String)
  }

  /// The provider filter; false includes current and former members, and nil omits it.
  public let currentMember: Bool?
  /// The validated route, with the state code normalized to uppercase ASCII.
  public let scope: Scope

  var path: String {
    var components = URLComponents()
    let limit: Int?
    switch scope {
    case .congressDistrict(let congress, let district, let stateCode):
      components.path = "/v3/member/congress/\(congress)/\(stateCode)/\(district)"
      limit = nil
    case .district(let district, let stateCode):
      components.path = "/v3/member/\(stateCode)/\(district)"
      limit = nil
    case .state(let size, let stateCode):
      components.path = "/v3/member/\(stateCode)"
      limit = size
    }
    components.queryItems = []
    if let currentMember {
      components.queryItems?.append(.init(name: "currentMember", value: String(currentMember)))
    }
    components.queryItems?.append(.init(name: "format", value: "json"))
    if let limit { components.queryItems?.append(.init(name: "limit", value: String(limit))) }
    return components.percentEncodedPath + "?" + (components.percentEncodedQuery ?? "")
  }

  /// Validates a geographic route without performing I/O.
  ///
  /// No route accepts an initial offset or modification window. Only the state route exposes
  /// an optional limit. District zero is allowed for at-large and delegate routes, but does not
  /// fill missing district fields in returned records.
  /// - Parameters:
  ///   - currentMember: The source filter, false by default; nil omits the parameter.
  ///   - scope: A geographic scope containing exactly two ASCII letters for the state code.
  ///     Territory codes and DC are accepted without a fixed jurisdiction allowlist.
  /// - Throws: `CongressInputError.invalidQuery` for an invalid code, nonpositive Congress,
  ///   negative district, or state limit outside 1 through 250.
  public init(currentMember: Bool? = false, scope: Scope) throws(CongressInputError) {
    self.currentMember = currentMember
    switch scope {
    case .congressDistrict(let congress, let district, let stateCode):
      guard congress > 0, district >= 0 else { throw .invalidQuery }
      self.scope = .congressDistrict(
        congress: congress, district: district, stateCode: try Self.normalized(stateCode))
    case .district(let district, let stateCode):
      guard district >= 0 else { throw .invalidQuery }
      self.scope = .district(district: district, stateCode: try Self.normalized(stateCode))
    case .state(let limit, let stateCode):
      if let limit, !(1...250).contains(limit) { throw .invalidQuery }
      self.scope = .state(limit: limit, stateCode: try Self.normalized(stateCode))
    }
  }

  private static func normalized(_ code: String) throws(CongressInputError) -> String {
    guard code.utf8.count == 2,
      code.utf8.allSatisfy({ (65...90).contains($0) || (97...122).contains($0) })
    else { throw .invalidQuery }
    return code.uppercased()
  }
}
