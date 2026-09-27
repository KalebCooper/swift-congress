/// The MemberPage response as published by Congress.gov.
///
/// A list record without `bioguideId` or `name` fails the whole page with a decoding error rather
/// than being skipped.
public struct MemberPage: Codable, Hashable, Sendable {
  /// The source `members` value.
  public let members: [MemberSummary]
  /// The source `pagination` value.
  public let pagination: Pagination
  /// Every source field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// The source `request` value; absent or null values remain nil.
  public let request: JSONValue?

  /// Decodes the original provider object.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    members = try c.decode([MemberSummary].self, forKey: .members)
    pagination = try c.decode(Pagination.self, forKey: .pagination)
    request = try c.decodeIfPresent(JSONValue.self, forKey: .request)
  }

  /// Encodes all retained source fields.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case members
    case pagination
    case request
  }
}

extension MemberPage: CongressCollection {
  /// Records in source order without local filtering.
  public var items: [MemberSummary] { members }
}
