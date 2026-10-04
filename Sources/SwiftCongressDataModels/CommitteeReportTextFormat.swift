/// A source text format and its open errata indicator; no asset bytes are fetched.
public struct CommitteeReportTextFormat: Codable, Hashable, Sendable {
  /// Original errata indicator, such as N; unknown values remain unchanged.
  public let isErrata: String?
  /// Every original field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// Open format label, unchanged.
  public let type: String?
  /// Original asset link, including a relative link if supplied; no base is guessed.
  public let url: String?

  /// Decodes the original provider object without normalizing its fields.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    isErrata = try c.decodeIfPresent(String.self, forKey: .isErrata)
    type = try c.decodeIfPresent(String.self, forKey: .type)
    url = try c.decodeIfPresent(String.self, forKey: .url)
  }

  /// Encodes every retained source field.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case isErrata
    case type
    case url
  }
}
