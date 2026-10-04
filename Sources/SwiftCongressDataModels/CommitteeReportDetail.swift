/// One response containing every report part in its published order.
public struct CommitteeReportDetail: Codable, Hashable, Sendable {
  /// All published parts, without collapsing the response to one record.
  public let committeeReports: [CommitteeReportPart]
  /// Every original field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// Original request metadata, when published.
  public let request: JSONValue?

  /// Decodes the original provider object without normalizing its fields.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    committeeReports = try c.decode([CommitteeReportPart].self, forKey: .committeeReports)
    request = try c.decodeIfPresent(JSONValue.self, forKey: .request)
  }

  /// Encodes every retained source field.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case committeeReports
    case request
  }
}
