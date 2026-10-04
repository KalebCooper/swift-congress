/// The open source code and optional name of a Senate communication type.
public struct CommitteeSenateCommunicationType: Codable, Hashable, Sendable {
  /// Source type code, including unrecognized future values.
  public let code: String
  /// Published descriptive name, without reconstruction.
  public let name: String?
  /// Every original field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]

  /// Decodes the original provider record.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    code = try c.decode(String.self, forKey: .code)
    name = try c.decodeIfPresent(String.self, forKey: .name)
  }

  /// Encodes every retained source field.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case code
    case name
  }
}
