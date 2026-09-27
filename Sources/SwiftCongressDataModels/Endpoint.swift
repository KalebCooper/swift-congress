#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// An immutable single HTTP operation on api.congress.gov, independent of networking.
///
/// ```swift
/// let key = try BillSourceIdentifier(congress: 6, number: "1", type: .houseBill)
/// let endpoint = Endpoint.bill(key)
/// ```
public struct Endpoint<Response>: Hashable, Sendable {
  /// The encoded path and query relative to https://api.congress.gov.
  public let path: String

  /// Accepts an HTTPS provider link with no credential, fragment, or credential query.
  public init?(link: URL) {
    guard let c = URLComponents(url: link, resolvingAgainstBaseURL: false),
      c.scheme?.lowercased() == "https", c.host?.lowercased() == "api.congress.gov",
      c.port == nil || c.port == 443, c.user == nil, c.password == nil, c.fragment == nil
    else { return nil }
    self.init(path: c.percentEncodedPath + (c.percentEncodedQuery.map { "?" + $0 } ?? ""))
  }

  /// Accepts an encoded v3 path; rejects dot segments, credentials, controls and fragments.
  /// `api_key` is never accepted in a URL. The SDK supplies it as an explicit header.
  public init?(path: String) {
    guard path.hasPrefix("/v3/"),
      path.utf8.allSatisfy({ (33...126).contains($0) && $0 != 35 && $0 != 92 }),
      let c = URLComponents(string: "https://api.congress.gov" + path),
      c.percentEncodedPath + (c.percentEncodedQuery.map { "?" + $0 } ?? "") == path,
      !c.path.contains("%"), !c.path.contains("\\"), !c.path.contains("//"),
      !c.path.utf8.contains(where: { $0 < 32 || $0 == 127 }),
      !c.path.split(separator: "/").contains(where: { $0 == "." || $0 == ".." }),
      !(c.queryItems ?? []).contains(where: { $0.name.lowercased() == "api_key" })
    else { return nil }
    self.path = path
  }

  static func builtIn(_ path: String) -> Self {
    guard let endpoint = Self(path: path) else {
      preconditionFailure("Fixed v3 paths with validated components are valid endpoints.")
    }
    return endpoint
  }
}

extension Endpoint where Response == BillDetail {
  /// Describes one bill by its Congress.gov source key, including historical surrogates.
  public static func bill(_ identifier: BillSourceIdentifier) -> Self {
    builtIn(
      "/v3/bill/\(identifier.congress)/\(identifier.type.rawValue)/\(identifier.number)?format=json"
    )
  }
  /// Describes one numbered bill.
  public static func bill(_ identifier: BillIdentifier) -> Self { bill(identifier.source) }
}

extension Endpoint where Response == BillPage {
  /// Describes one page of the matching bill inventory.
  public static func bills(matching query: BillQuery) -> Self { builtIn(query.path) }
}

extension Endpoint where Response == CongressPage {
  /// Describes one page of the all-era Congress inventory.
  public static func congresses(matching query: CongressQuery = .init()) -> Self {
    builtIn("/v3/congress?format=json&limit=\(query.limit)&offset=\(query.offset)")
  }
}

extension Endpoint where Response == BillActionPage {
  /// Describes one page of actions for a bill source record.
  public static func actions(for identifier: BillSourceIdentifier, page: CongressQuery = .init())
    -> Self
  {
    builtIn(
      "/v3/bill/\(identifier.congress)/\(identifier.type.rawValue)/\(identifier.number)/actions?format=json&limit=\(page.limit)&offset=\(page.offset)"
    )
  }
}

extension Endpoint where Response == MemberDetail {
  /// Describes one member record by its validated identifier, spelled as supplied.
  public static func member(_ identifier: MemberIdentifier) -> Self {
    builtIn("/v3/member/\(identifier.rawValue)?format=json")
  }
}

extension Endpoint where Response == MemberPage {
  /// Describes one page of the matching member inventory.
  public static func members(matching query: MemberQuery) -> Self { builtIn(query.path) }
}

extension Endpoint where Response == BillTextVersionPage {
  /// Describes one page of text-version metadata for a bill source record.
  public static func textVersions(
    for identifier: BillSourceIdentifier, page: CongressQuery = .init()
  ) -> Self {
    builtIn(
      "/v3/bill/\(identifier.congress)/\(identifier.type.rawValue)/\(identifier.number)/text?format=json&limit=\(page.limit)&offset=\(page.offset)"
    )
  }
  /// Describes one page of text-version metadata for a numbered bill.
  public static func textVersions(for identifier: BillIdentifier, page: CongressQuery = .init())
    -> Self
  {
    textVersions(for: identifier.source, page: page)
  }
}
