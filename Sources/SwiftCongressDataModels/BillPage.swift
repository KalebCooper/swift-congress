/// The BillPage response as published by Congress.gov.
public struct BillPage: Codable, Hashable, Sendable {
  /// The source `bills` value.
  public let bills: [Bill]
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
    bills = try c.decode([Bill].self, forKey: .bills)
    pagination = try c.decode(Pagination.self, forKey: .pagination)
    request = try c.decodeIfPresent(JSONValue.self, forKey: .request)
  }

  /// Encodes all retained source fields.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case bills
    case pagination
    case request
  }
}

extension BillPage: CongressCollection {
  /// Records in source order without local filtering.
  public var items: [Bill] { bills }
}
