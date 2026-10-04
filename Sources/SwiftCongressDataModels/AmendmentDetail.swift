/// One amendment detail response without following any nested links.
public struct AmendmentDetail: Codable, Hashable, Sendable {
  /// The published amendment record.
  public let amendment: Amendment
  /// Every original field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// Original request metadata, when supplied.
  public let request: JSONValue?

  /// Decodes the original provider object without normalizing its fields.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    amendment = try c.decode(Amendment.self, forKey: .amendment)
    request = try c.decodeIfPresent(JSONValue.self, forKey: .request)
  }

  /// Encodes every retained source field.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case amendment
    case request
  }
}
