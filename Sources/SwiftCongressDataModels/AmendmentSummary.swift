/// A sparse inventory, bill-list or amended-amendment reference.
public struct AmendmentSummary: Codable, Hashable, Sendable {
  /// Original Congress number.
  public let congress: Int
  /// Source description, distinct from purpose; omitted or null remains nil.
  public let description: String?
  /// Latest published action, without inferring a vote outcome.
  public let latestAction: AmendmentAction?
  /// Source amendment number, without numeric coercion.
  public let number: String
  /// Original purpose when supplied, distinct from description.
  public let purpose: String?
  /// Every original field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// Open amendment code, retaining original spelling.
  public let type: AmendmentType
  /// Original modification timestamp, unparsed.
  public let updateDate: String?
  /// Original reference URL; no linked response is fetched.
  public let url: String?

  /// Decodes the original provider object without normalizing its fields.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    congress = try c.decode(Int.self, forKey: .congress)
    description = try c.decodeIfPresent(String.self, forKey: .description)
    latestAction = try c.decodeIfPresent(AmendmentAction.self, forKey: .latestAction)
    number = try c.decode(String.self, forKey: .number)
    purpose = try c.decodeIfPresent(String.self, forKey: .purpose)
    type = try c.decode(AmendmentType.self, forKey: .type)
    updateDate = try c.decodeIfPresent(String.self, forKey: .updateDate)
    url = try c.decodeIfPresent(String.self, forKey: .url)
  }

  /// Encodes every retained source field.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case congress
    case description
    case latestAction
    case number
    case purpose
    case type
    case updateDate
    case url
  }
}
