/// The exact committee detail envelope.
public struct CommitteeDetail: Codable, Hashable, Sendable {
  /// The source committee profile.
  public let committee: CommitteeProfile
  /// Every original source field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// Published request metadata.
  public let request: JSONValue?

  /// Decodes the original provider object.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    committee = try c.decode(CommitteeProfile.self, forKey: .committee)
    request = try c.decodeIfPresent(JSONValue.self, forKey: .request)
  }

  /// Encodes every retained source field.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case committee
    case request
  }
}
