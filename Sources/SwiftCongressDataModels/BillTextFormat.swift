#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// One published format of a bill text version, as listed by Congress.gov.
///
/// A format is supplied link metadata. This module never retrieves the linked bytes, and the link's
/// file extension does not establish a media type. The format name stays the source string, so a
/// name this module has not seen decodes unchanged.
///
/// ```swift
/// for format in version.formats ?? [] {
///   print(format.type ?? "unnamed", format.url ?? "no link")
/// }
/// ```
public struct BillTextFormat: Codable, Hashable, Sendable {
  /// Every source field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// The source `type` value, such as `PDF` or `Formatted Text`; absent or null values remain nil.
  public let type: String?
  /// The source `url` value exactly as published; absent or null values remain nil.
  public let url: String?

  /// The source link parsed as an absolute URL, for convenience only.
  ///
  /// The value is nil when ``url`` is absent, contains characters that are not valid in a URL, or
  /// lacks a scheme or host. Parsing performs no I/O and does not check that the link resolves.
  /// ``url`` always keeps the published string, including one this property cannot parse.
  public var parsedURL: URL? {
    guard let url, let parsed = URL(string: url, encodingInvalidCharacters: false),
      parsed.scheme?.isEmpty == false, parsed.host?.isEmpty == false
    else { return nil }
    return parsed
  }

  /// Decodes the original provider object.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    type = try c.decodeIfPresent(String.self, forKey: .type)
    url = try c.decodeIfPresent(String.self, forKey: .url)
  }

  /// Encodes all retained source fields.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case type
    case url
  }
}
