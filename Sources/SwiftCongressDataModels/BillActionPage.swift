/// The BillActionPage response as published by Congress.gov.
public struct BillActionPage: Codable, Hashable, Sendable {
  /// The source `actions` value.
  public let actions: [BillAction]
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
    actions = try c.decode([BillAction].self, forKey: .actions)
    pagination = try c.decode(Pagination.self, forKey: .pagination)
    request = try c.decodeIfPresent(JSONValue.self, forKey: .request)
  }

  /// Encodes all retained source fields.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case actions
    case pagination
    case request
  }
}

extension BillActionPage: CongressCollection {
  /// Records in source order without local filtering.
  public var items: [BillAction] { actions }
}
