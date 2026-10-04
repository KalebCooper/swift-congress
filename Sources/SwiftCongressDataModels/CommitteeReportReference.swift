/// A published inventory or committee-associated report reference, preserving its report number and part separately.
public struct CommitteeReportReference: Codable, Hashable, Sendable {
  /// Open source chamber label, unchanged.
  public let chamber: String?
  /// Published report citation, without reconstruction.
  public let citation: String?
  /// Source Congress number.
  public let congress: Int
  /// Source report number, distinct from the part number.
  public let number: Int
  /// Source part number when published; never inferred from the URL.
  public let part: Int?
  /// Every original field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// Open report type with the exact source spelling.
  public let type: String
  /// Source modification timestamp, unchanged.
  public let updateDate: String?
  /// Published report link retained without fetching it.
  public let url: String?

  /// Decodes the original provider record.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    chamber = try c.decodeIfPresent(String.self, forKey: .chamber)
    citation = try c.decodeIfPresent(String.self, forKey: .citation)
    congress = try c.decode(Int.self, forKey: .congress)
    number = try c.decode(Int.self, forKey: .number)
    part = try c.decodeIfPresent(Int.self, forKey: .part)
    type = try c.decode(String.self, forKey: .type)
    updateDate = try c.decodeIfPresent(String.self, forKey: .updateDate)
    url = try c.decodeIfPresent(String.self, forKey: .url)
  }

  /// Encodes every retained source field.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case chamber
    case citation
    case congress
    case number
    case part
    case type
    case updateDate
    case url
  }
}
