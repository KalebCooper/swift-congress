/// The exact CRSReport detail envelope.
public struct CRSReportDetail: Codable, Hashable, Sendable {
  /// Every original source field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// The source report.
  public let report: CRSReport
  /// Published request metadata.
  public let request: JSONValue?

  /// Decodes the original provider object.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    report = try c.decode(CRSReport.self, forKey: .report)
    request = try c.decodeIfPresent(JSONValue.self, forKey: .request)
  }

  /// Encodes every retained source field.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case report = "CRSReport"
    case request
  }
}
