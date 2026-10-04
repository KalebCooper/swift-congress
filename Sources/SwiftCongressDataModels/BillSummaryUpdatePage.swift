/// A Congress.gov summary page retaining its original envelope.
public struct BillSummaryUpdatePage: Codable, Hashable, Sendable {
  /// Source pagination metadata; counts can change between requests.
  public let pagination: Pagination
  /// Every source field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// Source request metadata; absent or null remains nil.
  public let request: JSONValue?
  /// Summary entries in provider order, retaining repeats.
  public let summaries: [BillSummaryUpdate]

  /// Decodes the original provider object.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    pagination = try c.decode(Pagination.self, forKey: .pagination)
    request = try c.decodeIfPresent(JSONValue.self, forKey: .request)
    summaries = try c.decode([BillSummaryUpdate].self, forKey: .summaries)
  }

  /// Encodes all retained source fields.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case pagination
    case request
    case summaries
  }
}

extension BillSummaryUpdatePage: CongressCollection {
  /// Records in source order without local filtering or de-duplication.
  public var items: [BillSummaryUpdate] { summaries }
}
