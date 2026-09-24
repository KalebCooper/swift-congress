/// Provider pagination metadata; counts do not establish a stable snapshot.
public struct Pagination: Codable, Hashable, Sendable {
  /// The source `count` value.
  public let count: Int
  /// The source `next` value; absent or null values remain nil.
  public let next: String?
  /// The source `prev` value; absent or null values remain nil.
  public let prev: String?
  /// Every source field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]

  /// Decodes the original provider object.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    count = try c.decode(Int.self, forKey: .count)
    next = try c.decodeIfPresent(String.self, forKey: .next)
    prev = try c.decodeIfPresent(String.self, forKey: .prev)
  }

  /// Encodes all retained source fields.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case count
    case next
    case prev
  }
}
