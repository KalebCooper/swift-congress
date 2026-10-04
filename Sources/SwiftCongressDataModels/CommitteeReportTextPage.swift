/// One strictly paginated response containing report text metadata.
public struct CommitteeReportTextPage: Codable, Hashable, Sendable {
  /// Original count and continuation links.
  public let pagination: Pagination
  /// Every original field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// Original request metadata, when published.
  public let request: JSONValue?
  /// Original text records in source order.
  public let text: [CommitteeReportTextVersion]

  /// Decodes the original provider object without normalizing its fields.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    pagination = try c.decode(Pagination.self, forKey: .pagination)
    request = try c.decodeIfPresent(JSONValue.self, forKey: .request)
    text = try c.decode([CommitteeReportTextVersion].self, forKey: .text)
  }

  /// Encodes every retained source field.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case pagination
    case request
    case text
  }
}

extension CommitteeReportTextPage: CongressCollection {
  /// Text records in source order, without a bill-text overrun allowance.
  public var items: [CommitteeReportTextVersion] { text }
}
