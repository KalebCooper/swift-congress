/// A treaty reference associated with a report, distinct from a bill reference.
public struct CommitteeReportTreaty: Codable, Hashable, Sendable {
  /// Source Congress number.
  public let congress: Int
  /// Source treaty number, retained as an integer.
  public let number: Int
  /// Source treaty part, including letter parts when supplied; never inferred from a URL.
  public let part: String?
  /// Every original field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// Original reference URL, retained without fetching it.
  public let url: String?

  /// Decodes the original provider object without normalizing its fields.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    congress = try c.decode(Int.self, forKey: .congress)
    number = try c.decode(Int.self, forKey: .number)
    part = try c.decodeIfPresent(String.self, forKey: .part)
    url = try c.decodeIfPresent(String.self, forKey: .url)
  }

  /// Encodes every retained source field.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case congress
    case number
    case part
    case url
  }
}
