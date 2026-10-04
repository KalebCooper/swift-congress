/// One bill summary version in provider order; no latest-version or stable-identity inference.
public struct BillSummary: Codable, Hashable, Sendable {
  /// Source action date, unparsed; absent or null remains nil.
  public let actionDate: String?
  /// Source action description, preserving unknown wording.
  public let actionDesc: String?
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
    text = try c.decodeIfPresent(String.self, forKey: .text)
    updateDate = try c.decodeIfPresent(String.self, forKey: .updateDate)
    versionCode = try c.decodeIfPresent(String.self, forKey: .versionCode)
  }

  /// Encodes all retained source fields.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case actionDate
    case actionDesc
    case text
    case updateDate
    case versionCode
  }
}
