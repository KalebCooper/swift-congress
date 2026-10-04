/// A source related-bill association; no symmetric relationship or identical text is inferred.
public struct RelatedBill: Codable, Hashable, Sendable {
  /// Source Congress number.
  public let congress: Int
  /// Latest published action, without additional retrieval.
  public let latestAction: BillAction?
  /// Source integer bill number, without coercion from text.
  public let number: Int
  /// Every source field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// All relationship authorities and descriptions in source order.
  public let relationshipDetails: [BillRelationshipDetail]?
  /// Source title, unchanged.
  public let title: String?
  /// Open source bill type, unchanged.
  public let type: String?
  /// Published bill link retained without following it.
  public let url: String?

  /// Decodes the original provider object.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    congress = try c.decode(Int.self, forKey: .congress)
    latestAction = try c.decodeIfPresent(BillAction.self, forKey: .latestAction)
    number = try c.decode(Int.self, forKey: .number)
    relationshipDetails = try c.decodeIfPresent(
      [BillRelationshipDetail].self, forKey: .relationshipDetails)
    title = try c.decodeIfPresent(String.self, forKey: .title)
    type = try c.decodeIfPresent(String.self, forKey: .type)
    url = try c.decodeIfPresent(String.self, forKey: .url)
  }

  /// Encodes all retained source fields.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case congress
    case latestAction
    case number
    case relationshipDetails
    case title
    case type
    case url
  }
}
