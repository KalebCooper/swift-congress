/// One original bill association response, retaining pagination and request metadata.
public struct BillCommitteePage: Codable, Hashable, Sendable {
  /// Published associations in source order, including duplicates.
  public let committees: [BillCommittee]
  /// Original source pagination metadata.
  public let pagination: Pagination
  /// Every source field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// Original request metadata, when present.
  public let request: JSONValue?

  /// Decodes the original provider object.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    committees = try c.decode([BillCommittee].self, forKey: .committees)
    pagination = try c.decode(Pagination.self, forKey: .pagination)
    request = try c.decodeIfPresent(JSONValue.self, forKey: .request)
  }

  /// Encodes all retained source fields.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case committees
    case pagination
    case request
  }
}

extension BillCommitteePage: CongressCollection {
  /// Published associations in source order, without deduplication.
  public var items: [BillCommittee] { committees }
}
