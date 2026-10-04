/// Cosponsor resource metadata with separate active and withdrawal-inclusive counts.
public struct AmendmentCosponsorResource: Codable, Hashable, Sendable {
  /// Original source count, not a locally calculated total.
  public let count: Int?
  /// Original count including withdrawn cosponsors, independent of count.
  public let countIncludingWithdrawnCosponsors: Int?
  /// Every original field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// Original resource URL, without automatic retrieval.
  public let url: String?

  /// Decodes the original provider object without normalizing its fields.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    count = try c.decodeIfPresent(Int.self, forKey: .count)
    countIncludingWithdrawnCosponsors = try c.decodeIfPresent(
      Int.self, forKey: .countIncludingWithdrawnCosponsors)
    url = try c.decodeIfPresent(String.self, forKey: .url)
  }

  /// Encodes every retained source field.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case count
    case countIncludingWithdrawnCosponsors
    case url
  }
}
