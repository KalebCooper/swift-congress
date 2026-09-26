/// One entry of a member detail record's `terms` array as published by Congress.gov.
///
/// Chamber, role, and state strings are source vocabulary and are never normalized. Years are
/// source integers, not dates. A delegate or resident commissioner may carry no `district`.
public struct MemberTerm: Codable, Hashable, Sendable {
  /// The source `chamber` value; absent or null values remain nil.
  public let chamber: String?
  /// The source `congress` value; absent or null values remain nil.
  public let congress: Int?
  /// The source `district` value; absent or null values remain nil.
  public let district: Int?
  /// The source `endYear` value; absent or null values remain nil.
  public let endYear: Int?
  /// The source `memberType` value; absent or null values remain nil.
  public let memberType: String?
  /// Every source field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// The source `startYear` value; absent or null values remain nil.
  public let startYear: Int?
  /// The source `stateCode` value; absent or null values remain nil.
  public let stateCode: String?
  /// The source `stateName` value; absent or null values remain nil.
  public let stateName: String?

  /// Decodes the original provider object.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    chamber = try c.decodeIfPresent(String.self, forKey: .chamber)
    congress = try c.decodeIfPresent(Int.self, forKey: .congress)
    district = try c.decodeIfPresent(Int.self, forKey: .district)
    endYear = try c.decodeIfPresent(Int.self, forKey: .endYear)
    memberType = try c.decodeIfPresent(String.self, forKey: .memberType)
    startYear = try c.decodeIfPresent(Int.self, forKey: .startYear)
    stateCode = try c.decodeIfPresent(String.self, forKey: .stateCode)
    stateName = try c.decodeIfPresent(String.self, forKey: .stateName)
  }

  /// Encodes all retained source fields.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case chamber
    case congress
    case district
    case endYear
    case memberType
    case startYear
    case stateCode
    case stateName
  }
}
