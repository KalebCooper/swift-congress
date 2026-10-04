/// The source flags describing a nomination reference.
public struct CommitteeNominationType: Codable, Hashable, Sendable {
  /// Whether the source explicitly identifies a civilian nomination.
  public let isCivilian: Bool?
  /// Whether the source explicitly identifies a military nomination.
  public let isMilitary: Bool?
  /// Every original field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]

  /// Decodes the original provider record.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    isCivilian = try c.decodeIfPresent(Bool.self, forKey: .isCivilian)
    isMilitary = try c.decodeIfPresent(Bool.self, forKey: .isMilitary)
  }

  /// Encodes every retained source field.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case isCivilian
    case isMilitary
  }
}
