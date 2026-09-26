/// The MemberDepiction response as published by Congress.gov.
///
/// The image is not fetched and no license is inferred from the attribution text.
public struct MemberDepiction: Codable, Hashable, Sendable {
  /// The source `attribution` value; absent or null values remain nil.
  public let attribution: String?
  /// The source `imageUrl` value; absent or null values remain nil.
  public let imageUrl: String?
  /// Every source field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]

  /// Decodes the original provider object.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    attribution = try c.decodeIfPresent(String.self, forKey: .attribution)
    imageUrl = try c.decodeIfPresent(String.self, forKey: .imageUrl)
  }

  /// Encodes all retained source fields.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case attribution
    case imageUrl
  }
}
