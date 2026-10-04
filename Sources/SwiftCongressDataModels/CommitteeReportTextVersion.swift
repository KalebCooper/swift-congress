/// A text record preserving its nested formats without inferring a report part.
public struct CommitteeReportTextVersion: Codable, Hashable, Sendable {
  /// Published formats in source order; absent or null remains nil.
  public let formats: [CommitteeReportTextFormat]?
  /// Every original field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]

  /// Decodes the original provider object without normalizing its fields.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    formats = try c.decodeIfPresent([CommitteeReportTextFormat].self, forKey: .formats)
  }

  /// Encodes every retained source field.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case formats
  }
}
