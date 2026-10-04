/// One published bill cosponsor, retaining source order and withdrawal information.
public struct BillCosponsor: Codable, Hashable, Sendable {
  /// Source member identifier, preserved without identity matching.
  public let bioguideId: String
  /// Source district; missing or null remains nil, including Senate records.
  public let district: Int?
  /// Source first name, without reconstruction.
  public let firstName: String?
  /// Source display name, unchanged.
  public let fullName: String?
  /// Source original-cosponsor flag; absence does not imply false.
  public let isOriginalCosponsor: Bool?
  /// Source last name, unchanged.
  public let lastName: String?
  /// Source middle name, when published.
  public let middleName: String?
  /// Open source party code, unchanged.
  public let party: String?
  /// Every source field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// Source sponsorship date, unparsed.
  public let sponsorshipDate: String?
  /// Source withdrawal date, unparsed; absence does not establish current status.
  public let sponsorshipWithdrawnDate: String?
  /// Open source state value, unchanged.
  public let state: String?
  /// Source member URL, retained as metadata without fetching.
  public let url: String?

  /// Decodes the original provider object.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    bioguideId = try c.decode(String.self, forKey: .bioguideId)
    district = try c.decodeIfPresent(Int.self, forKey: .district)
    firstName = try c.decodeIfPresent(String.self, forKey: .firstName)
    fullName = try c.decodeIfPresent(String.self, forKey: .fullName)
    isOriginalCosponsor = try c.decodeIfPresent(Bool.self, forKey: .isOriginalCosponsor)
    lastName = try c.decodeIfPresent(String.self, forKey: .lastName)
    middleName = try c.decodeIfPresent(String.self, forKey: .middleName)
    party = try c.decodeIfPresent(String.self, forKey: .party)
    sponsorshipDate = try c.decodeIfPresent(String.self, forKey: .sponsorshipDate)
    sponsorshipWithdrawnDate = try c.decodeIfPresent(String.self, forKey: .sponsorshipWithdrawnDate)
    state = try c.decodeIfPresent(String.self, forKey: .state)
    url = try c.decodeIfPresent(String.self, forKey: .url)
  }

  /// Encodes all retained source fields.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case bioguideId
    case district
    case firstName
    case fullName
    case isOriginalCosponsor
    case lastName
    case middleName
    case party
    case sponsorshipDate
    case sponsorshipWithdrawnDate
    case state
    case url
  }
}
