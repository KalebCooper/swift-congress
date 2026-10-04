/// One published amendment note, retaining its original text.
public struct AmendmentNote: Codable, Hashable, Sendable {
  /// Every original field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// Original note text; omitted or null remains nil.
  public let text: String?

  /// Decodes the original provider object without normalizing its fields.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    text = try c.decodeIfPresent(String.self, forKey: .text)
  }

  /// Encodes every retained source field.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case text
  }
}
