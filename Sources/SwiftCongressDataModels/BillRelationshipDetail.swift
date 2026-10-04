/// One source assertion about a related bill, preserving its identifying authority.
public struct BillRelationshipDetail: Codable, Hashable, Sendable {
  /// Open source authority, such as CRS or House.
  public let identifiedBy: String?
  /// Every source field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// Open relationship description, without inferred equivalence.
  public let type: String?

  /// Decodes the original provider object.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    identifiedBy = try c.decodeIfPresent(String.self, forKey: .identifiedBy)
    type = try c.decodeIfPresent(String.self, forKey: .type)
  }

  /// Encodes all retained source fields.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case identifiedBy
    case type
  }
}
