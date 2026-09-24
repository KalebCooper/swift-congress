/// A chamber session; missing session numbers remain nil.
public struct CongressSession: Codable, Hashable, Sendable {
  /// The source `chamber` value; absent or null values remain nil.
  public let chamber: String?
  /// The source `endDate` value; absent or null values remain nil.
  public let endDate: String?
  /// The source `number` value; absent or null values remain nil.
  public let number: Int?
  /// Every source field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// The source `startDate` value; absent or null values remain nil.
  public let startDate: String?
  /// The source `type` value; absent or null values remain nil.
  public let type: String?

  /// Decodes the original provider object.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    chamber = try c.decodeIfPresent(String.self, forKey: .chamber)
    endDate = try c.decodeIfPresent(String.self, forKey: .endDate)
    number = try c.decodeIfPresent(Int.self, forKey: .number)
    startDate = try c.decodeIfPresent(String.self, forKey: .startDate)
    type = try c.decodeIfPresent(String.self, forKey: .type)
  }

  /// Encodes all retained source fields.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case chamber
    case endDate
    case number
    case startDate
    case type
  }
}
