/// One activity associated with a bill and committee, in source order.
public struct BillCommitteeActivity: Codable, Hashable, Sendable {
  /// Source activity timestamp, unparsed.
  public let date: String?
  /// Open source activity description, preserving capitalization.
  public let name: String?
  /// Every source field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]

  /// Decodes the original provider object.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    date = try c.decodeIfPresent(String.self, forKey: .date)
    name = try c.decodeIfPresent(String.self, forKey: .name)
  }

  /// Encodes all retained source fields.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case date
    case name
  }
}
