/// The CongressPage response as published by Congress.gov.
public struct CongressPage: Codable, Hashable, Sendable {
  /// The source `congresses` value.
  public let congresses: [Congress]
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
    congresses = try c.decode([Congress].self, forKey: .congresses)
    pagination = try c.decode(Pagination.self, forKey: .pagination)
    request = try c.decodeIfPresent(JSONValue.self, forKey: .request)
  }

  /// Encodes all retained source fields.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case congresses
    case pagination
    case request
  }
}

extension CongressPage: CongressCollection {
  /// Records in source order without local filtering.
  public var items: [Congress] { congresses }
}
