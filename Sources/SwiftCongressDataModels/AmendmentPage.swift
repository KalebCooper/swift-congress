/// One strictly paginated inventory or bill-amendment response.
public struct AmendmentPage: Codable, Hashable, Sendable {
  /// Original amendments in source order, preserving duplicates.
  public let amendments: [AmendmentSummary]
  /// Original count and continuation links.
  public let pagination: Pagination
  /// Every original field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// Original request metadata, when supplied.
  public let request: JSONValue?

  /// Decodes the original provider object without normalizing its fields.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    amendments = try c.decode([AmendmentSummary].self, forKey: .amendments)
    pagination = try c.decode(Pagination.self, forKey: .pagination)
    request = try c.decodeIfPresent(JSONValue.self, forKey: .request)
  }

  /// Encodes every retained source field.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case amendments
    case pagination
    case request
  }
}

extension AmendmentPage: CongressCollection {
  /// Original amendment records without a page-overrun allowance.
  public var items: [AmendmentSummary] { amendments }
}
