/// The BioguidePosition response as published in the official Bioguide export.
public struct BioguidePosition: Codable, Hashable, Sendable {
  /// The source `congressAffiliation` value; absent or null values remain nil.
  public let congressAffiliation: BioguideAffiliation?
  /// The source `endCirca` value; absent or null values remain nil.
  public let endCirca: Bool?
  /// The source `endDate` value; absent or null values remain nil.
  public let endDate: String?
  /// The source `job` value; absent or null values remain nil.
  public let job: JSONValue?
  /// Every source field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// The source `startCirca` value; absent or null values remain nil.
  public let startCirca: Bool?
  /// The source `startDate` value; absent or null values remain nil.
  public let startDate: String?

  /// Decodes the original provider object.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    congressAffiliation = try c.decodeIfPresent(
      BioguideAffiliation.self, forKey: .congressAffiliation)
    endCirca = try c.decodeIfPresent(Bool.self, forKey: .endCirca)
    endDate = try c.decodeIfPresent(String.self, forKey: .endDate)
    job = try c.decodeIfPresent(JSONValue.self, forKey: .job)
    startCirca = try c.decodeIfPresent(Bool.self, forKey: .startCirca)
    startDate = try c.decodeIfPresent(String.self, forKey: .startDate)
  }

  /// Encodes all retained source fields.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case congressAffiliation
    case endCirca
    case endDate
    case job
    case startCirca
    case startDate
  }
}
