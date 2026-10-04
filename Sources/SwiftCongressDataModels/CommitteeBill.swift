/// A committee's published bill relationship, without inferred title or detail.
public struct CommitteeBill: Codable, Hashable, Sendable {
  /// Source relationship action timestamp, unchanged.
  public let actionDate: String?
  /// Source Congress number.
  public let congress: Int
  /// Source bill number, retaining its string representation.
  public let number: String
  /// Every original field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// Open source relationship label, unchanged.
  public let relationshipType: String?
  /// Open bill type with the exact source spelling.
  public let type: BillType
  /// Source modification timestamp, unchanged.
  public let updateDate: String?
  /// Published bill link retained without fetching it.
  public let url: String?

  /// Decodes the original provider record.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    actionDate = try c.decodeIfPresent(String.self, forKey: .actionDate)
    congress = try c.decode(Int.self, forKey: .congress)
    number = try c.decode(String.self, forKey: .number)
    relationshipType = try c.decodeIfPresent(String.self, forKey: .relationshipType)
    type = try c.decode(BillType.self, forKey: .type)
    updateDate = try c.decodeIfPresent(String.self, forKey: .updateDate)
    url = try c.decodeIfPresent(String.self, forKey: .url)
  }

  /// Encodes every retained source field.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case actionDate
    case congress
    case number
    case relationshipType
    case type
    case updateDate
    case url
  }
}
