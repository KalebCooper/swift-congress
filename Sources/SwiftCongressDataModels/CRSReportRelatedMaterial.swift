/// A related provider record without inferred identity or deduplication.
public struct CRSReportRelatedMaterial: Codable, Hashable, Sendable {
  /// Published Congress number.
  public let congress: Int?
  /// Original number scalar, including string law citations and numeric bill numbers.
  public let number: JSONValue?
  /// Every original source field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// Published title; missing and null remain nil.
  public let title: String?
  /// Open source type code.
  public let type: String?
  /// The uppercase URL source field, retained unchanged.
  public let url: String?

  /// Decodes the original provider object.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    congress = try c.decodeIfPresent(Int.self, forKey: .congress)
    number = try c.decodeIfPresent(JSONValue.self, forKey: .number)
    title = try c.decodeIfPresent(String.self, forKey: .title)
    type = try c.decodeIfPresent(String.self, forKey: .type)
    url = try c.decodeIfPresent(String.self, forKey: .url)
  }

  /// Encodes every retained source field.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case congress
    case number
    case title
    case type
    case url = "URL"
  }
}
