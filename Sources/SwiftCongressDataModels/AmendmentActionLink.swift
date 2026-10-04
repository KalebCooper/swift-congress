/// An original amendment-action link, including raw vote references.
public struct AmendmentActionLink: Codable, Hashable, Sendable {
  /// Original link name without interpretation.
  public let name: String?
  /// Every original field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// Original link URL; no chamber request follows.
  public let url: String?

  /// Decodes the original provider object without normalizing its fields.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    name = try c.decodeIfPresent(String.self, forKey: .name)
    url = try c.decodeIfPresent(String.self, forKey: .url)
  }

  /// Encodes every retained source field.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case name
    case url
  }
}
