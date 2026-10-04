/// A source format link; the SDK does not retrieve its content.
public struct CRSReportFormat: Codable, Hashable, Sendable {
  /// Open format label, such as PDF or HTML.
  public let format: String?
  /// Every original source field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// Supplied format URL, unchanged.
  public let url: String?

  /// Decodes the original provider object.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    format = try c.decodeIfPresent(String.self, forKey: .format)
    url = try c.decodeIfPresent(String.self, forKey: .url)
  }

  /// Encodes every retained source field.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case format
    case url
  }
}
