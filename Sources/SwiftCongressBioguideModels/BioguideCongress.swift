/// The BioguideCongress response as published in the official Bioguide export.
public struct BioguideCongress: Codable, Hashable, Sendable {
  /// The source `congressNumber` value.
  public let congressNumber: Int
  /// The source `congressType` value.
  public let congressType: String
  /// The source `endDate` value; absent or null values remain nil.
  public let endDate: String?
  /// The source `name` value.
  public let name: String
  /// Every source field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// The source `startDate` value; absent or null values remain nil.
  public let startDate: String?

  /// Decodes the original provider object.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    congressNumber = try c.decode(Int.self, forKey: .congressNumber)
    congressType = try c.decode(String.self, forKey: .congressType)
    endDate = try c.decodeIfPresent(String.self, forKey: .endDate)
    name = try c.decode(String.self, forKey: .name)
    startDate = try c.decodeIfPresent(String.self, forKey: .startDate)
  }

  /// Encodes all retained source fields.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case congressNumber
    case congressType
    case endDate
    case name
    case startDate
  }
}
