/// A CRS report with source metadata and supplied links; no linked asset is fetched.
public struct CRSReport: Codable, Hashable, Sendable {
  /// Authors in source order.
  public let authors: [CRSReportAuthor]?
  /// Open provider content category, unchanged.
  public let contentType: String?
  /// Detail version supplied by the source; not inferred from list versions.
  public let currentVersion: Int?
  /// Supplied format links in source order.
  public let formats: [CRSReportFormat]?
  /// Source report identity, unchanged.
  public let id: String
  /// Source publication timestamp, unparsed.
  public let publishDate: String?
  /// Every original source field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// Related source references, preserving duplicates.
  public let relatedMaterials: [CRSReportRelatedMaterial]?
  /// Open provider status, without local interpretation.
  public let status: String?
  /// Original report summary text.
  public let summary: String?
  /// Source title.
  public let title: String
  /// Topics in source order.
  public let topics: [CRSReportTopic]?
  /// Source update timestamp, independent of publication date.
  public let updateDate: String?
  /// Source link, retained even when it has no scheme.
  public let url: String?

  /// Decodes the original provider object.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    authors = try c.decodeIfPresent([CRSReportAuthor].self, forKey: .authors)
    contentType = try c.decodeIfPresent(String.self, forKey: .contentType)
    currentVersion = try c.decodeIfPresent(Int.self, forKey: .currentVersion)
    formats = try c.decodeIfPresent([CRSReportFormat].self, forKey: .formats)
    id = try c.decode(String.self, forKey: .id)
    publishDate = try c.decodeIfPresent(String.self, forKey: .publishDate)
    relatedMaterials = try c.decodeIfPresent(
      [CRSReportRelatedMaterial].self, forKey: .relatedMaterials)
    status = try c.decodeIfPresent(String.self, forKey: .status)
    summary = try c.decodeIfPresent(String.self, forKey: .summary)
    title = try c.decode(String.self, forKey: .title)
    topics = try c.decodeIfPresent([CRSReportTopic].self, forKey: .topics)
    updateDate = try c.decodeIfPresent(String.self, forKey: .updateDate)
    url = try c.decodeIfPresent(String.self, forKey: .url)
  }

  /// Encodes every retained source field.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case authors
    case contentType
    case currentVersion
    case formats
    case id
    case publishDate
    case relatedMaterials
    case status
    case summary
    case title
    case topics
    case updateDate
    case url
  }
}
