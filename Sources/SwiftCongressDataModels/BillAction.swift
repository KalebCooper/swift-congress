/// The BillAction response as published by Congress.gov.
public struct BillAction: Codable, Hashable, Sendable {
  /// The source `actionCode` value; absent or null values remain nil.
  public let actionCode: String?
  /// The source `actionDate` value; absent or null values remain nil.
  public let actionDate: String?
  /// The source `actionTime` value; absent or null values remain nil.
  public let actionTime: String?
  /// Every source field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// The source `recordedVotes` value; absent or null values remain nil.
  public let recordedVotes: [JSONValue]?
  /// The source `sourceSystem` value; absent or null values remain nil.
  public let sourceSystem: JSONValue?
  /// The source `text` value; absent or null values remain nil.
  public let text: String?
  /// The source `type` value; absent or null values remain nil.
  public let type: String?

  /// Decodes the original provider object.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    actionCode = try c.decodeIfPresent(String.self, forKey: .actionCode)
    actionDate = try c.decodeIfPresent(String.self, forKey: .actionDate)
    actionTime = try c.decodeIfPresent(String.self, forKey: .actionTime)
    recordedVotes = try c.decodeIfPresent([JSONValue].self, forKey: .recordedVotes)
    sourceSystem = try c.decodeIfPresent(JSONValue.self, forKey: .sourceSystem)
    text = try c.decodeIfPresent(String.self, forKey: .text)
    type = try c.decodeIfPresent(String.self, forKey: .type)
  }

  /// Encodes all retained source fields.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case actionCode
    case actionDate
    case actionTime
    case recordedVotes
    case sourceSystem
    case text
    case type
  }
}
