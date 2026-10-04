/// One Senate communication response with original pagination and request metadata.
public struct CommitteeSenateCommunicationPage: Codable, Hashable, Sendable {
  /// Original pagination count and continuation links.
  public let pagination: Pagination
  /// Every original field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// Original request metadata, when published.
  public let request: JSONValue?
  /// Senate communication references in source order, preserving types and duplicates.
  public let senateCommunications: [CommitteeSenateCommunication]

  /// Decodes the original provider record.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    pagination = try c.decode(Pagination.self, forKey: .pagination)
    request = try c.decodeIfPresent(JSONValue.self, forKey: .request)
    senateCommunications = try c.decode(
      [CommitteeSenateCommunication].self, forKey: .senateCommunications)
  }

  /// Encodes every retained source field.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case pagination
    case request
    case senateCommunications
  }
}

extension CommitteeSenateCommunicationPage: CongressCollection {
  /// Senate communication references in source order, preserving types and duplicates.
  public var items: [CommitteeSenateCommunication] { senateCommunications }
}
