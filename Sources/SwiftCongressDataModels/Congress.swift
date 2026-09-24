/// A U.S. Congress discovered from the provider inventory.
public struct Congress: Codable, Hashable, Sendable {
  /// The source `endYear` value; absent or null values remain nil.
  public let endYear: String?
  /// The source `name` value.
  public let name: String
  /// Every source field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// The source `sessions` value; absent or null values remain nil.
  public let sessions: [CongressSession]?
  /// The source `startYear` value; absent or null values remain nil.
  public let startYear: String?
  /// The source `updateDate` value; absent or null values remain nil.
  public let updateDate: String?
  /// The source `url` value.
  public let url: String

  /// Decodes the original provider object.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    endYear = try c.decodeIfPresent(String.self, forKey: .endYear)
    name = try c.decode(String.self, forKey: .name)
    sessions = try c.decodeIfPresent([CongressSession].self, forKey: .sessions)
    startYear = try c.decodeIfPresent(String.self, forKey: .startYear)
    updateDate = try c.decodeIfPresent(String.self, forKey: .updateDate)
    url = try c.decode(String.self, forKey: .url)
  }

  /// Encodes all retained source fields.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case endYear
    case name
    case sessions
    case startYear
    case updateDate
    case url
  }
}
