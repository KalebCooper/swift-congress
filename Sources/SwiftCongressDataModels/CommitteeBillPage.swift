/// One committee bill response with its nested resource metadata.
public struct CommitteeBillPage: Codable, Hashable, Sendable {
  /// Bill relationships in source order, preserving duplicates.
  public let bills: [CommitteeBill]
  /// Count published inside the committee-bills object, separate from pagination.
  public let count: Int
  /// Original pagination count and continuation links.
  public let pagination: Pagination
  /// Every envelope field, including unknown nested fields and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// Original request metadata, when published.
  public let request: JSONValue?
  /// Resource URL published inside the committee-bills object, without fetching it.
  public let url: String

  /// Decodes the nested source object without rewriting counts or links.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    let resource = try c.nestedContainer(keyedBy: ResourceKeys.self, forKey: .committeeBills)
    bills = try resource.decode([CommitteeBill].self, forKey: .bills)
    count = try resource.decode(Int.self, forKey: .count)
    pagination = try c.decode(Pagination.self, forKey: .pagination)
    request = try c.decodeIfPresent(JSONValue.self, forKey: .request)
    url = try resource.decode(String.self, forKey: .url)
  }

  /// Encodes the complete original envelope.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case committeeBills = "committee-bills"
    case pagination
    case request
  }

  private enum ResourceKeys: String, CodingKey {
    case bills
    case count
    case url
  }
}

extension CommitteeBillPage: CongressCollection {
  /// Bill relationships in source order, preserving duplicates.
  public var items: [CommitteeBill] { bills }
}
