/// A published legislative subject or separate policy area with open historical vocabulary.
public struct BillSubject: Codable, Hashable, Sendable {
  /// Source subject name, unchanged.
  public let name: String
  /// Every source field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// Source modification timestamp, unparsed.
  public let updateDate: String?

  /// Decodes the original provider object.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    name = try c.decode(String.self, forKey: .name)
    updateDate = try c.decodeIfPresent(String.self, forKey: .updateDate)
  }

  /// Encodes all retained source fields.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case name
    case updateDate
  }
}
