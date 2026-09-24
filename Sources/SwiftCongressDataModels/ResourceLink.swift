/// The ResourceLink response as published by Congress.gov.
public struct ResourceLink: Codable, Hashable, Sendable {
  /// The source `count` value; absent or null values remain nil.
  public let count: Int?
  /// Every source field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// The source `url` value; absent or null values remain nil.
  public let url: String?

  /// Decodes the original provider object.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    count = try c.decodeIfPresent(Int.self, forKey: .count)
    url = try c.decodeIfPresent(String.self, forKey: .url)
  }

  /// Encodes all retained source fields.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case count
    case url
  }
}
