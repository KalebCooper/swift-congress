/// A bill record retaining historical omissions and all source fields.
public struct Bill: Codable, Hashable, Sendable {
  /// The source `actions` value; absent or null values remain nil.
  public let actions: ResourceLink?
  /// The source `congress` value.
  public let congress: Int
  /// The source `introducedDate` value; absent or null values remain nil.
  public let introducedDate: String?
  /// The source `latestAction` value; absent or null values remain nil.
  public let latestAction: BillAction?
  /// Source law citations in provider order; missing or null remains nil.
  public let laws: [BillLawReference]?
  /// The source `legislationUrl` value; absent or null values remain nil.
  public let legislationUrl: String?
  /// The source `number` value.
  public let number: String
  /// The source `originChamber` value; absent or null values remain nil.
  public let originChamber: String?
  /// Every source field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// The source `sponsors` value; absent or null values remain nil.
  public let sponsors: [JSONValue]?
  /// The source `textVersions` value; absent or null values remain nil.
  public let textVersions: ResourceLink?
  /// The source `title` value.
  public let title: String
  /// The source `type` value.
  public let type: BillType
  /// The source `updateDate` value; absent or null values remain nil.
  public let updateDate: String?
  /// The source `url` value; absent or null values remain nil.
  public let url: String?

  /// Decodes the original provider object.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    actions = try c.decodeIfPresent(ResourceLink.self, forKey: .actions)
    congress = try c.decode(Int.self, forKey: .congress)
    introducedDate = try c.decodeIfPresent(String.self, forKey: .introducedDate)
    latestAction = try c.decodeIfPresent(BillAction.self, forKey: .latestAction)
    laws = try c.decodeIfPresent([BillLawReference].self, forKey: .laws)
    legislationUrl = try c.decodeIfPresent(String.self, forKey: .legislationUrl)
    number = try c.decode(String.self, forKey: .number)
    originChamber = try c.decodeIfPresent(String.self, forKey: .originChamber)
    sponsors = try c.decodeIfPresent([JSONValue].self, forKey: .sponsors)
    textVersions = try c.decodeIfPresent(ResourceLink.self, forKey: .textVersions)
    title = try c.decode(String.self, forKey: .title)
    type = try c.decode(BillType.self, forKey: .type)
    updateDate = try c.decodeIfPresent(String.self, forKey: .updateDate)
    url = try c.decodeIfPresent(String.self, forKey: .url)
  }

  /// Encodes all retained source fields.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case actions
    case congress
    case introducedDate
    case latestAction
    case laws
    case legislationUrl
    case number
    case originChamber
    case sponsors
    case textVersions
    case title
    case type
    case updateDate
    case url
  }
}
