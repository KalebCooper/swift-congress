/// One report-reference response with its original pagination and request metadata.
public struct CommitteeReportPage: Codable, Hashable, Sendable {
  /// Original pagination count and continuation links.
  public let pagination: Pagination
  /// Every envelope field, including unknown fields and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// Report references in source order, preserving parts and duplicate rows.
  public let reports: [CommitteeReportReference]
  /// Original request metadata, when published.
  public let request: JSONValue?

  /// Decodes the original reports array without rewriting counts or links.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    pagination = try c.decode(Pagination.self, forKey: .pagination)
    reports = try c.decode([CommitteeReportReference].self, forKey: .reports)
    request = try c.decodeIfPresent(JSONValue.self, forKey: .request)
  }

  /// Encodes the complete original envelope.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case pagination
    case reports
    case request
  }
}

extension CommitteeReportPage: CongressCollection {
  /// Report references in source order, preserving parts and duplicate rows.
  public var items: [CommitteeReportReference] { reports }
}
