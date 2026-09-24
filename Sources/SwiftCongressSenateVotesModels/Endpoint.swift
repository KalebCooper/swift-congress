#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
/// One immutable single-document operation on www.senate.gov.
/// Describing an endpoint performs no network I/O or bulk traversal.
public struct Endpoint<Response>: Hashable, Sendable {
  /// The encoded origin-relative source path.
  public let path: String
  /// The absolute source URL, with no embedded credential or fragment.
  public var url: URL {
    guard let result = URL(string: "https://www.senate.gov" + path) else {
      preconditionFailure("Validated paths form a URL on the fixed source origin.")
    }
    return result
  }

  /// Accepts only HTTPS links on this service's exact origin.
  public init?(link: URL) {
    guard let c = URLComponents(url: link, resolvingAgainstBaseURL: false),
      c.scheme == "https", c.host?.lowercased() == "www.senate.gov",
      c.port == nil || c.port == 443,
      c.user == nil, c.password == nil, c.fragment == nil, c.query == nil
    else { return nil }
    self.init(path: c.percentEncodedPath)
  }

  /// Validates a source path without accepting another origin, queries, or dot segments.
  public init?(path: String) {
    guard path.hasPrefix("/legislative/"), !path.contains("%"), !path.contains("//"),
      path.utf8.allSatisfy({
        (48...57).contains($0) || (65...90).contains($0) || (97...122).contains($0)
          || [45, 46, 47, 95].contains($0)
      }),
      !path.split(separator: "/").contains(where: { $0 == "." || $0 == ".." })
    else { return nil }
    self.path = path
  }

  static func builtIn(_ path: String) -> Self {
    guard let endpoint = Self(path: path) else {
      preconditionFailure("Validated source components form a valid path.")
    }
    return endpoint
  }
}
