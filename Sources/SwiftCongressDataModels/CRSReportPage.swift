/// One exact CRSReports inventory envelope.
public struct CRSReportPage: Codable, Hashable, Sendable {
  /// Published count and links.
  public let pagination: Pagination
  /// Every original source field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// Report summaries in source order.
  public let reports: [CRSReportSummary]
  /// Published request metadata.
  public let request: JSONValue?

  /// Decodes the original provider object.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    pagination = try c.decode(Pagination.self, forKey: .pagination)
    reports = try c.decode([CRSReportSummary].self, forKey: .reports)
    request = try c.decodeIfPresent(JSONValue.self, forKey: .request)
  }

  /// Encodes every retained source field.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case pagination
    case reports = "CRSReports"
    case request
  }
}

extension CRSReportPage: CongressCollection {
  /// Report summaries in source order, preserving duplicates.
  public var items: [CRSReportSummary] { reports }
}
