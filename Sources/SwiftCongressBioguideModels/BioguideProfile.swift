/// The BioguideProfile response as published in the official Bioguide export.
public struct BioguideProfile: Codable, Hashable, Sendable {
  /// The source `asset` value; absent or null values remain nil.
  public let asset: [JSONValue]?
  /// The source `birthCirca` value; absent or null values remain nil.
  public let birthCirca: Bool?
  /// The source `birthDate` value; absent or null values remain nil.
  public let birthDate: String?
  /// The source `birthDateUnknown` value; absent or null values remain nil.
  public let birthDateUnknown: Bool?
  /// The source `creativeWork` value; absent or null values remain nil.
  public let creativeWork: [JSONValue]?
  /// The source `deathCirca` value; absent or null values remain nil.
  public let deathCirca: Bool?
  /// The source `deathDate` value; absent or null values remain nil.
  public let deathDate: String?
  /// The source `deleted` value; absent or null values remain nil.
  public let deleted: Bool?
  /// The source `familyName` value.
  public let familyName: String
  /// The source `givenName` value.
  public let givenName: String
  /// The source `image` value; absent or null values remain nil.
  public let image: [JSONValue]?
  /// The source `jobPositions` value.
  public let jobPositions: [BioguidePosition]
  /// The source `middleName` value; absent or null values remain nil.
  public let middleName: String?
  /// The source `profileText` value.
  public let profileText: String
  /// The source `publishedDate` value; absent or null values remain nil.
  public let publishedDate: String?
  /// The source `publishedDateISO` value; absent or null values remain nil.
  public let publishedDateISO: String?
  /// Every source field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// The source `relationship` value; absent or null values remain nil.
  public let relationship: [JSONValue]?
  /// The source `researchRecord` value; absent or null values remain nil.
  public let researchRecord: [JSONValue]?
  /// The source `usCongressBioId` value.
  public let usCongressBioId: String

  /// Decodes the original provider object.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    asset = try c.decodeIfPresent([JSONValue].self, forKey: .asset)
    birthCirca = try c.decodeIfPresent(Bool.self, forKey: .birthCirca)
    birthDate = try c.decodeIfPresent(String.self, forKey: .birthDate)
    birthDateUnknown = try c.decodeIfPresent(Bool.self, forKey: .birthDateUnknown)
    creativeWork = try c.decodeIfPresent([JSONValue].self, forKey: .creativeWork)
    deathCirca = try c.decodeIfPresent(Bool.self, forKey: .deathCirca)
    deathDate = try c.decodeIfPresent(String.self, forKey: .deathDate)
    deleted = try c.decodeIfPresent(Bool.self, forKey: .deleted)
    familyName = try c.decode(String.self, forKey: .familyName)
    givenName = try c.decode(String.self, forKey: .givenName)
    image = try c.decodeIfPresent([JSONValue].self, forKey: .image)
    jobPositions = try c.decode([BioguidePosition].self, forKey: .jobPositions)
    middleName = try c.decodeIfPresent(String.self, forKey: .middleName)
    profileText = try c.decode(String.self, forKey: .profileText)
    publishedDate = try c.decodeIfPresent(String.self, forKey: .publishedDate)
    publishedDateISO = try c.decodeIfPresent(String.self, forKey: .publishedDateISO)
    relationship = try c.decodeIfPresent([JSONValue].self, forKey: .relationship)
    researchRecord = try c.decodeIfPresent([JSONValue].self, forKey: .researchRecord)
    usCongressBioId = try c.decode(String.self, forKey: .usCongressBioId)
  }

  /// Encodes all retained source fields.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case asset
    case birthCirca
    case birthDate
    case birthDateUnknown
    case creativeWork
    case deathCirca
    case deathDate
    case deleted
    case familyName
    case givenName
    case image
    case jobPositions
    case middleName
    case profileText
    case publishedDate
    case publishedDateISO
    case relationship
    case researchRecord
    case usCongressBioId
  }
}
