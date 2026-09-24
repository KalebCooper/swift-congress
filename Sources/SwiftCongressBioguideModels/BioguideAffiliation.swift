/// The BioguideAffiliation response as published in the official Bioguide export.
public struct BioguideAffiliation: Codable, Hashable, Sendable {
  /// The source `caucusAffiliation` value; absent or null values remain nil.
  public let caucusAffiliation: [JSONValue]?
  /// The source `congress` value; absent or null values remain nil.
  public let congress: BioguideCongress?
  /// The source `electionType` value; absent or null values remain nil.
  public let electionType: String?
  /// The source `partyAffiliation` value; absent or null values remain nil.
  public let partyAffiliation: [JSONValue]?
  /// Every source field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// The source `represents` value; absent or null values remain nil.
  public let represents: JSONValue?

  /// Decodes the original provider object.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    caucusAffiliation = try c.decodeIfPresent([JSONValue].self, forKey: .caucusAffiliation)
    congress = try c.decodeIfPresent(BioguideCongress.self, forKey: .congress)
    electionType = try c.decodeIfPresent(String.self, forKey: .electionType)
    partyAffiliation = try c.decodeIfPresent([JSONValue].self, forKey: .partyAffiliation)
    represents = try c.decodeIfPresent(JSONValue.self, forKey: .represents)
  }

  /// Encodes all retained source fields.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case caucusAffiliation
    case congress
    case electionType
    case partyAffiliation
    case represents
  }
}
