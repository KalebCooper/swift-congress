/// A bill cosponsor envelope preserving active and withdrawal-inclusive source totals.
public struct BillCosponsorPage: Codable, Hashable, Sendable {
  /// Cosponsors in provider order, including withdrawn entries when published.
  public let cosponsors: [BillCosponsor]
  /// Source `pagination.countIncludingWithdrawnCosponsors`; missing or null remains nil.
  public let countIncludingWithdrawnCosponsors: Int?
  /// Original pagination, whose `count` excludes withdrawals in the recorded chain.
  public let pagination: Pagination
  /// Every original envelope field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// Source request metadata; absent or null remains nil.
  public let request: JSONValue?

  /// Decodes the original provider object and its nested inclusive count.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    cosponsors = try c.decode([BillCosponsor].self, forKey: .cosponsors)
    let counts = try c.nestedContainer(keyedBy: CountKeys.self, forKey: .pagination)
    countIncludingWithdrawnCosponsors = try counts.decodeIfPresent(
      Int.self, forKey: .countIncludingWithdrawnCosponsors)
    pagination = try c.decode(Pagination.self, forKey: .pagination)
    request = try c.decodeIfPresent(JSONValue.self, forKey: .request)
  }

  /// Encodes all retained source fields without replacing the active count.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case cosponsors
    case pagination
    case request
  }

  private enum CountKeys: String, CodingKey {
    case countIncludingWithdrawnCosponsors
  }
}

extension BillCosponsorPage: CongressCollection {
  /// Records in source order, without deduplication or withdrawal filtering.
  public var items: [BillCosponsor] { cosponsors }
}

extension BillCosponsorPage: CongressPageCount {
  var continuationCount: Int { countIncludingWithdrawnCosponsors ?? pagination.count }
}
