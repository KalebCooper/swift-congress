/// An explicit committee relationship supplied by Congress.gov.
public struct CommitteeReference: Codable, Hashable, Sendable {
  /// The name as published on this reference.
  public let name: String?
  /// Every original source field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// The source system code, without prefix interpretation.
  public let systemCode: String?
  /// The source URL, never followed automatically.
  public let url: String?

  /// Decodes the original provider object.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    name = try c.decodeIfPresent(String.self, forKey: .name)
    systemCode = try c.decodeIfPresent(String.self, forKey: .systemCode)
    url = try c.decodeIfPresent(String.self, forKey: .url)
  }

  /// Encodes every retained source field.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case name
    case systemCode
    case url
  }
}
