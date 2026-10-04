/// One nomination-reference response with original pagination and request metadata.
public struct CommitteeNominationPage: Codable, Hashable, Sendable {
  /// Nomination references in source order, preserving parts and duplicates.
  public let nominations: [CommitteeNomination]
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
    nominations = try c.decode([CommitteeNomination].self, forKey: .nominations)
    pagination = try c.decode(Pagination.self, forKey: .pagination)
    request = try c.decodeIfPresent(JSONValue.self, forKey: .request)
  }

  /// Encodes every retained source field.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case nominations
    case pagination
    case request
  }
}

extension CommitteeNominationPage: CongressCollection {
  /// Nomination references in source order, preserving parts and duplicates.
  public var items: [CommitteeNomination] { nominations }
}
