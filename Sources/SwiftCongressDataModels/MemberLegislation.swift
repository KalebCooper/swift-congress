/// Legislation listed for a member, including bill and amendment records.
///
/// Amendment rows may omit bill fields and publish a null type. No bill identity is synthesized.
public struct MemberLegislation: Codable, Hashable, Sendable {
  /// Source amendment number, distinct from a bill number; absent or null remains nil.
  public let amendmentNumber: String?
  /// The source Congress number.
  public let congress: Int
  /// Source introduction date, unparsed.
  public let introducedDate: String?
  /// Source latest action; absent or null remains nil.
  public let latestAction: BillAction?
  /// Source bill number; amendment rows may omit it.
  public let number: String?
  /// Original policy-area object, retaining nullable names and unknown fields.
  public let policyArea: JSONValue?
  /// Every source field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// Source title without a fabricated fallback.
  public let title: String?
  /// Open source legislation type, without inferring missing values from URLs.
  public let type: String?
  /// Source record URL, preserved without fetching it.
  public let url: String?

  /// Decodes the original provider object.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    amendmentNumber = try c.decodeIfPresent(String.self, forKey: .amendmentNumber)
    congress = try c.decode(Int.self, forKey: .congress)
    introducedDate = try c.decodeIfPresent(String.self, forKey: .introducedDate)
    latestAction = try c.decodeIfPresent(BillAction.self, forKey: .latestAction)
    number = try c.decodeIfPresent(String.self, forKey: .number)
    policyArea = try c.decodeIfPresent(JSONValue.self, forKey: .policyArea)
    title = try c.decodeIfPresent(String.self, forKey: .title)
    type = try c.decodeIfPresent(String.self, forKey: .type)
    url = try c.decodeIfPresent(String.self, forKey: .url)
  }

  /// Encodes all retained source fields.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case amendmentNumber
    case congress
    case introducedDate
    case latestAction
    case number
    case policyArea
    case title
    case type
    case url
  }
}
