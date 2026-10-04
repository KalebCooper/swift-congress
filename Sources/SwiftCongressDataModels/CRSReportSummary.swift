/// A CRS inventory record with independent source dates and version.
public struct CRSReportSummary: Codable, Hashable, Sendable {
  /// Open provider content category, unchanged.
  public let contentType: String?
  /// Source report identity, unchanged.
  public let id: String
  /// Source publication timestamp, unparsed.
  public let publishDate: String?
  /// Every original source field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// Open provider status, without local interpretation.
  public let status: String?
  /// Source title.
  public let title: String
  /// Source update timestamp, independent of publication date.
  public let updateDate: String?
  /// Source link, retained even when it has no scheme.
  public let url: String?
  /// Inventory version, not a historical-version availability promise.
  public let version: Int?

  /// Decodes the original provider object.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    contentType = try c.decodeIfPresent(String.self, forKey: .contentType)
    id = try c.decode(String.self, forKey: .id)
    publishDate = try c.decodeIfPresent(String.self, forKey: .publishDate)
    status = try c.decodeIfPresent(String.self, forKey: .status)
    title = try c.decode(String.self, forKey: .title)
    updateDate = try c.decodeIfPresent(String.self, forKey: .updateDate)
    url = try c.decodeIfPresent(String.self, forKey: .url)
    version = try c.decodeIfPresent(Int.self, forKey: .version)
  }

  /// Encodes every retained source field.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case contentType
    case id
    case publishDate
    case status
    case title
    case updateDate
    case url
    case version
  }
}
