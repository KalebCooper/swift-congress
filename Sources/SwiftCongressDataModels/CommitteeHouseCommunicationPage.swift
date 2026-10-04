/// One House communication response with original pagination and request metadata.
public struct CommitteeHouseCommunicationPage: Codable, Hashable, Sendable {
  /// House communication references in source order, preserving types and duplicates.
  public let houseCommunications: [CommitteeHouseCommunication]
  /// Original pagination count and continuation links.
  public let pagination: Pagination
  /// Every original field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// Original request metadata, when published.
  public let request: JSONValue?

  /// Decodes the original provider record.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    houseCommunications = try c.decode(
      [CommitteeHouseCommunication].self, forKey: .houseCommunications)
    pagination = try c.decode(Pagination.self, forKey: .pagination)
    request = try c.decodeIfPresent(JSONValue.self, forKey: .request)
  }

  /// Encodes every retained source field.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case houseCommunications
    case pagination
    case request
  }
}

extension CommitteeHouseCommunicationPage: CongressCollection {
  /// House communication references in source order, preserving types and duplicates.
  public var items: [CommitteeHouseCommunication] { houseCommunications }
}
