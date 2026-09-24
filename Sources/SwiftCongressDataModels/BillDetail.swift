/// The BillDetail response as published by Congress.gov.
public struct BillDetail: Codable, Hashable, Sendable {
  /// The source `bill` value.
  public let bill: Bill
  /// Every source field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// The source `request` value; absent or null values remain nil.
  public let request: JSONValue?

  /// Decodes the original provider object.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    bill = try c.decode(Bill.self, forKey: .bill)
    request = try c.decodeIfPresent(JSONValue.self, forKey: .request)
  }

  /// Encodes all retained source fields.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case bill
    case request
  }
}
