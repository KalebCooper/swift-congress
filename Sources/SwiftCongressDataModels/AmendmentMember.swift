/// A sponsor or on-behalf member retaining source identity and role metadata.
public struct AmendmentMember: Codable, Hashable, Sendable {
  /// Original Bioguide identifier, without cross-service matching.
  public let bioguideId: String?
  /// Original district number; absent or null remains nil.
  public let district: Int?
  /// Original first name.
  public let firstName: String?
  /// Original full name without reconstruction.
  public let fullName: String?
  /// Original last name.
  public let lastName: String?
  /// Original middle name when supplied.
  public let middleName: String?
  /// Open source party label.
  public let party: String?
  /// Every original field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// Open source state or territory code.
  public let state: String?
  /// Original on-behalf role, distinct from the sponsors array.
  public let type: String?
  /// Original member reference URL; no profile is fetched.
  public let url: String?

  /// Decodes the original provider object without normalizing its fields.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    bioguideId = try c.decodeIfPresent(String.self, forKey: .bioguideId)
    district = try c.decodeIfPresent(Int.self, forKey: .district)
    firstName = try c.decodeIfPresent(String.self, forKey: .firstName)
    fullName = try c.decodeIfPresent(String.self, forKey: .fullName)
    lastName = try c.decodeIfPresent(String.self, forKey: .lastName)
    middleName = try c.decodeIfPresent(String.self, forKey: .middleName)
    party = try c.decodeIfPresent(String.self, forKey: .party)
    state = try c.decodeIfPresent(String.self, forKey: .state)
    type = try c.decodeIfPresent(String.self, forKey: .type)
    url = try c.decodeIfPresent(String.self, forKey: .url)
  }

  /// Encodes every retained source field.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case bioguideId
    case district
    case firstName
    case fullName
    case lastName
    case middleName
    case party
    case state
    case type
    case url
  }
}
