#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// One House year or section index; section links must be retrieved independently.
public struct HouseVoteIndex: Codable, Hashable, HouseResponse, Sendable {
  /// The source HTML, retained without extracting or reinterpreting descriptive prose.
  public let html: String
  /// Additional official section-index URLs in published order.
  public let sections: [URL]
  /// Explicit roll links in this document, preserving order and duplicates.
  public let votes: [HouseVoteReference]

  /// Extracts the verified House index link forms from at most 4 MiB of UTF-8 HTML.
  /// It skips comments and never treats a year index as XML or invents missing roll numbers.
  public static func decode(_ data: Data, sourceURL: URL) throws(HouseDecodingError) -> Self {
    guard !Task.isCancelled else { throw .cancelled }
    guard data.count <= 4_194_304 else { throw .limitExceeded }
    guard Endpoint<Self>(link: sourceURL) != nil,
      let source = URLComponents(url: sourceURL, resolvingAgainstBaseURL: false),
      let html = String(data: data, encoding: .utf8), html.lowercased().contains("<html"),
      html.lowercased().contains("roll call")
    else { throw .invalidDocument }
    let parts = source.path.split(separator: "/")
    guard parts.count == 3, let year = Int(parts[1]) else { throw .invalidDocument }
    var sections: [URL] = []
    var votes: [HouseVoteReference] = []
    var remaining = html[...]
    while let opening = remaining.firstIndex(of: "<") {
      guard !Task.isCancelled else { throw .cancelled }
      remaining = remaining[opening...]
      if remaining.hasPrefix("<!--") {
        guard let end = remaining.range(of: "-->") else { throw .invalidDocument }
        remaining = remaining[end.upperBound...]; continue
      }
      guard let end = remaining.firstIndex(of: ">") else { throw .invalidDocument }
      let tag = String(remaining[remaining.index(after: remaining.startIndex)..<end])
      remaining = remaining[remaining.index(after: end)...]
      guard let raw = href(in: tag) else { continue }
      let link = raw.split(separator: "&amp;", omittingEmptySubsequences: false).joined(
        separator: "&")
      guard let absolute = URL(string: link, relativeTo: sourceURL)?.absoluteURL,
        let c = URLComponents(url: absolute, resolvingAgainstBaseURL: false),
        c.host?.lowercased() == "clerk.house.gov", c.user == nil, c.password == nil,
        c.port == nil || c.port == 443, c.fragment == nil,
        c.scheme == "https" || c.scheme == "http"
      else { continue }
      if c.path == "/cgi-bin/vote.asp" {
        let pairs = c.queryItems ?? []
        guard pairs.count == 2, pairs.filter({ $0.name == "year" }).count == 1,
          pairs.filter({ $0.name == "rollnumber" }).count == 1,
          let linkedYear = pairs.first(where: { $0.name == "year" })?.value.flatMap(Int.init),
          linkedYear == year,
          let number = pairs.first(where: { $0.name == "rollnumber" })?.value.flatMap(Int.init),
          let identifier = try? HouseVoteIdentifier(number: number, year: year)
        else { throw .invalidDocument }
        votes.append(HouseVoteReference(identifier: identifier, sourceLink: raw))
      } else {
        let name = String(c.path.split(separator: "/").last ?? "")
        if name.hasPrefix("ROLL_"), name.hasSuffix(".asp") {
          let digits = name.dropFirst(5).dropLast(4)
          guard !digits.isEmpty, digits.utf8.allSatisfy({ (48...57).contains($0) }),
            c.path == "/evs/\(year)/" + name, c.query == nil,
            let endpoint = Endpoint<Self>(path: c.path)
          else { throw .invalidDocument }
          sections.append(endpoint.url)
        }
      }
    }
    return Self(html: html, sections: sections, votes: votes)
  }

  private static func href(in tag: String) -> String? {
    var rest = tag[...]
    guard let first = rest.first, first == "a" || first == "A" else { return nil }
    rest = rest.dropFirst()
    guard rest.first?.isWhitespace == true else { return nil }
    while !rest.isEmpty {
      rest = rest.drop(while: { $0.isWhitespace })
      let name = rest.prefix(while: { !$0.isWhitespace && $0 != "=" })
      guard !name.isEmpty else { return nil }
      rest = rest.dropFirst(name.count).drop(while: { $0.isWhitespace })
      guard rest.first == "=" else { return nil }
      rest = rest.dropFirst().drop(while: { $0.isWhitespace })
      guard let quote = rest.first, quote == "\"" || quote == "'" else { return nil }
      rest = rest.dropFirst()
      guard let end = rest.firstIndex(of: quote) else { return nil }
      let value = String(rest[..<end])
      rest = rest[rest.index(after: end)...]
      if name.lowercased() == "href" { return value }
    }
    return nil
  }
}

extension Endpoint where Response == HouseVoteIndex {
  /// Describes the year index; retrieving it does not retrieve its section links.
  public static func index(year: Int) throws(HouseInputError) -> Self {
    guard (1...9999).contains(year) else { throw .invalidIdentifier }
    return builtIn("/evs/\(year)/index.asp")
  }
}

extension HouseVoteRequest where Response == HouseVoteIndex {
  /// Describes one year-index document.
  public static func index(year: Int) throws(HouseInputError) -> Self {
    Self(endpoint: try .index(year: year))
  }
}
