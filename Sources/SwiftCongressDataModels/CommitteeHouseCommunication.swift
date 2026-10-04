/// A House committee's communication reference with original source identity.
public struct CommitteeHouseCommunication: Codable, Hashable, Sendable {
  /// Published chamber, without an inferred default.
  public let chamber: String?
  /// Source communication type, preserving its open code.
  public let communicationType: CommitteeHouseCommunicationType
  /// Source Congress number.
  public let congress: Int
  /// Source communication number, distinct from its type.
  public let number: Int
  /// Every original field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// Original referral date, unchanged.
  public let referralDate: String?
  /// Original modification date, unchanged.
  public let updateDate: String?
  /// Published communication link retained without fetching it.
  public let url: String?

  /// Decodes the original provider record.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    chamber = try c.decodeIfPresent(String.self, forKey: .chamber)
    communicationType = try c.decode(
      CommitteeHouseCommunicationType.self, forKey: .communicationType)
    congress = try c.decode(Int.self, forKey: .congress)
    number = try c.decode(Int.self, forKey: .number)
    referralDate = try c.decodeIfPresent(String.self, forKey: .referralDate)
    updateDate = try c.decodeIfPresent(String.self, forKey: .updateDate)
    url = try c.decodeIfPresent(String.self, forKey: .url)
  }

  /// Encodes every retained source field.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case chamber
    case communicationType
    case congress
    case number
    case referralDate
    case updateDate
    case url
  }
}
