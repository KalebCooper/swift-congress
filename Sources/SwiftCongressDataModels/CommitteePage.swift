/// One committee directory envelope.
public struct CommitteePage: Codable, Hashable, Sendable {
  /// Committee summaries in source order.
  public let committees: [CommitteeSummary]
  /// Published count and continuation links.
  public let pagination: Pagination
  /// Every original source field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// Published request metadata.
  public let request: JSONValue?

  /// Decodes the original provider object.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    committees = try c.decode([CommitteeSummary].self, forKey: .committees)
    pagination = try c.decode(Pagination.self, forKey: .pagination)
    request = try c.decodeIfPresent(JSONValue.self, forKey: .request)
  }

  /// Encodes every retained source field.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case committees
    case pagination
    case request
  }
}

extension CommitteePage: CongressCollection {
  /// Committee summaries in source order, preserving duplicates.
  public var items: [CommitteeSummary] { committees }
}
