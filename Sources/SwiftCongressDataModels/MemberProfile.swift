/// A member detail record retaining every source field.
///
/// Typed fields are views over ``rawFields``. Contact, leadership, previous-name, and
/// party-history data (`addressInformation`, `leadership`, `previousNames`, `partyHistory`)
/// are retained only in ``rawFields``. Birth and death years are the source's strings, as every
/// recorded detail that publishes them does.
/// `currentMember` is the source's status at retrieval, separate from the historical ``terms``.
public struct MemberProfile: Codable, Hashable, Sendable {
  /// The source `bioguideId` value.
  public let bioguideId: String
  /// The source `birthYear` value; absent or null values remain nil.
  public let birthYear: String?
  /// The source `cosponsoredLegislation` value; absent or null values remain nil.
  public let cosponsoredLegislation: ResourceLink?
  /// The source `currentMember` value; absent or null values remain nil.
  public let currentMember: Bool?
  /// The source `deathYear` value, a string such as `"2021"`; absent or null values remain nil.
  ///
  /// The recorded details of living members omit the key.
  public let deathYear: String?
  /// The source `depiction` value; absent or null values remain nil.
  public let depiction: MemberDepiction?
  /// The source `directOrderName` value; absent or null values remain nil.
  public let directOrderName: String?
  /// The source `district` value; absent or null values remain nil.
  public let district: Int?
  /// The source `firstName` value; absent or null values remain nil.
  public let firstName: String?
  /// The source `honorificName` value; absent or null values remain nil.
  public let honorificName: String?
  /// The source `invertedOrderName` value; absent or null values remain nil.
  public let invertedOrderName: String?
  /// The source `lastName` value; absent or null values remain nil.
  public let lastName: String?
  /// The source `middleName` value; absent or null values remain nil.
  public let middleName: String?
  /// The source `officialWebsiteUrl` value; absent or null values remain nil.
  public let officialWebsiteUrl: String?
  /// Every source field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// The source `sponsoredLegislation` value; absent or null values remain nil.
  public let sponsoredLegislation: ResourceLink?
  /// The source `state` value; absent or null values remain nil.
  public let state: String?
  /// The source `terms` array; absent or null values remain nil.
  public let terms: [MemberTerm]?
  /// The source `updateDate` value; absent or null values remain nil.
  public let updateDate: String?

  /// Decodes the original provider object.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    bioguideId = try c.decode(String.self, forKey: .bioguideId)
    birthYear = try c.decodeIfPresent(String.self, forKey: .birthYear)
    cosponsoredLegislation = try c.decodeIfPresent(
      ResourceLink.self, forKey: .cosponsoredLegislation)
    currentMember = try c.decodeIfPresent(Bool.self, forKey: .currentMember)
    deathYear = try c.decodeIfPresent(String.self, forKey: .deathYear)
    depiction = try c.decodeIfPresent(MemberDepiction.self, forKey: .depiction)
    directOrderName = try c.decodeIfPresent(String.self, forKey: .directOrderName)
    district = try c.decodeIfPresent(Int.self, forKey: .district)
    firstName = try c.decodeIfPresent(String.self, forKey: .firstName)
    honorificName = try c.decodeIfPresent(String.self, forKey: .honorificName)
    invertedOrderName = try c.decodeIfPresent(String.self, forKey: .invertedOrderName)
    lastName = try c.decodeIfPresent(String.self, forKey: .lastName)
    middleName = try c.decodeIfPresent(String.self, forKey: .middleName)
    officialWebsiteUrl = try c.decodeIfPresent(String.self, forKey: .officialWebsiteUrl)
    sponsoredLegislation = try c.decodeIfPresent(ResourceLink.self, forKey: .sponsoredLegislation)
    state = try c.decodeIfPresent(String.self, forKey: .state)
    terms = try c.decodeIfPresent([MemberTerm].self, forKey: .terms)
    updateDate = try c.decodeIfPresent(String.self, forKey: .updateDate)
  }

  /// Encodes all retained source fields.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case bioguideId
    case birthYear
    case cosponsoredLegislation
    case currentMember
    case deathYear
    case depiction
    case directOrderName
    case district
    case firstName
    case honorificName
    case invertedOrderName
    case lastName
    case middleName
    case officialWebsiteUrl
    case sponsoredLegislation
    case state
    case terms
    case updateDate
  }
}
