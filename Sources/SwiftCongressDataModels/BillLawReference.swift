/// A source law citation attached to a bill, without a reconstructed law URL or identity.
public struct BillLawReference: Codable, Hashable, Sendable {
  /// The source citation number, such as `119-1`; missing or null remains nil.
  public let number: String?
  /// Every source field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// The source label, such as `Public Law`; unknown values remain unchanged.
  public let type: String?

  /// Decodes a source citation without interpreting its number or category label.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    number = try c.decodeIfPresent(String.self, forKey: .number)
    type = try c.decodeIfPresent(String.self, forKey: .type)
  }

  /// Encodes every retained source field.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case number
    case type
  }
}
