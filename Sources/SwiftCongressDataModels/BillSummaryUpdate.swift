/// One published summary feed entry with its associated bill and chamber metadata.
public struct BillSummaryUpdate: Codable, Hashable, Sendable {
  /// Source action date, unparsed; absent or null remains nil.
  public let actionDate: String?
  /// Source action description, preserving unknown wording.
  public let actionDesc: String?
  /// The bill supplied by the feed, retaining its source identity and fields.
  public let bill: Bill
  /// Source chamber name, without a closed vocabulary.
  public let currentChamber: String?
  /// Source chamber code, including unknown codes.
  public let currentChamberCode: String?
  /// Source summary publication timestamp, unparsed.
  public let lastSummaryUpdateDate: String?
  /// Every source field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// Original source HTML, without rendering or sanitization.
  public let text: String?
  /// Source record update timestamp, distinct from the action date.
  public let updateDate: String?
  /// Open source version code, preserving leading zeros and unknown values.
  public let versionCode: String?

  /// Decodes the original provider object.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    actionDate = try c.decodeIfPresent(String.self, forKey: .actionDate)
    actionDesc = try c.decodeIfPresent(String.self, forKey: .actionDesc)
    bill = try c.decode(Bill.self, forKey: .bill)
    currentChamber = try c.decodeIfPresent(String.self, forKey: .currentChamber)
    currentChamberCode = try c.decodeIfPresent(String.self, forKey: .currentChamberCode)
    lastSummaryUpdateDate = try c.decodeIfPresent(String.self, forKey: .lastSummaryUpdateDate)
    text = try c.decodeIfPresent(String.self, forKey: .text)
    updateDate = try c.decodeIfPresent(String.self, forKey: .updateDate)
    versionCode = try c.decodeIfPresent(String.self, forKey: .versionCode)
  }

  /// Encodes all retained source fields.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case actionDate
    case actionDesc
    case bill
    case currentChamber
    case currentChamberCode
    case lastSummaryUpdateDate
    case text
    case updateDate
    case versionCode
  }
}
