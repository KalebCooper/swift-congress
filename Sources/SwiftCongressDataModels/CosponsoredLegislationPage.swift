/// A member's cosponsored legislation page with its original envelope.
public struct CosponsoredLegislationPage: Codable, Hashable, Sendable {
  /// Legislation in provider order, retaining repeats and amendment records.
  public let cosponsoredLegislation: [MemberLegislation]
  /// Source pagination metadata; counts can change between requests.
  public let pagination: Pagination
  /// Every source field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// Original request metadata; absent or null remains nil.
  public let request: JSONValue?

  /// Decodes the original provider object.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    cosponsoredLegislation = try c.decode([MemberLegislation].self, forKey: .cosponsoredLegislation)
    pagination = try c.decode(Pagination.self, forKey: .pagination)
    request = try c.decodeIfPresent(JSONValue.self, forKey: .request)
  }

  /// Encodes all retained source fields.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case cosponsoredLegislation
    case pagination
    case request
  }
}

extension CosponsoredLegislationPage: CongressCollection {
  /// Records in source order without local filtering or de-duplication.
  public var items: [MemberLegislation] { cosponsoredLegislation }
}
