/// A bill reference associated with a report, retaining its source string number.
public struct CommitteeReportBill: Codable, Hashable, Sendable {
  /// Source Congress number.
  public let congress: Int
  /// Source bill number without numeric coercion.
  public let number: String
  /// Every original field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// Open bill or resolution code, retaining source spelling.
  public let type: String
  /// Original reference URL, retained without fetching it.
  public let url: String?

  /// Decodes the original provider object without normalizing its fields.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    congress = try c.decode(Int.self, forKey: .congress)
    number = try c.decode(String.self, forKey: .number)
    type = try c.decode(String.self, forKey: .type)
    url = try c.decodeIfPresent(String.self, forKey: .url)
  }

  /// Encodes every retained source field.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case congress
    case number
    case type
    case url
  }
}
