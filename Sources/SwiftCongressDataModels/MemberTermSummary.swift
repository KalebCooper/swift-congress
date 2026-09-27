/// One entry of a member list record's `terms.item` array as published by Congress.gov.
///
/// The recorded list entries carry only a chamber and years; Congress numbers, roles, and
/// districts appear on the detail record's ``MemberTerm``, and any other key lands in
/// ``rawFields``. Years are source integers, not dates.
public struct MemberTermSummary: Codable, Hashable, Sendable {
  /// The source `chamber` value; absent or null values remain nil.
  public let chamber: String?
  /// The source `endYear` value; absent or null values remain nil.
  public let endYear: Int?
  /// Every source field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// The source `startYear` value; absent or null values remain nil.
  public let startYear: Int?

  /// Decodes the original provider object.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    chamber = try c.decodeIfPresent(String.self, forKey: .chamber)
    endYear = try c.decodeIfPresent(Int.self, forKey: .endYear)
    startYear = try c.decodeIfPresent(Int.self, forKey: .startYear)
  }

  /// Encodes all retained source fields.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case chamber
    case endYear
    case startYear
  }
}
