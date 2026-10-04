/// One published report part with independent relationships and text resource metadata.
public struct CommitteeReportPart: Codable, Hashable, Sendable {
  /// Bills under the singular source key, in source order; missing is distinct from empty in rawFields.
  public let associatedBill: [CommitteeReportBill]?
  /// Treaty references in source order, independent of any associated bills.
  public let associatedTreaties: [CommitteeReportTreaty]?
  /// Open source chamber label.
  public let chamber: String?
  /// Original citation without reconstruction.
  public let citation: String?
  /// Published committee references in order, including an explicit empty array.
  public let committees: [CommitteeReference]?
  /// Source Congress number.
  public let congress: Int
  /// Source conference flag without inference from inventory filter behavior.
  public let isConferenceReport: Bool?
  /// Original issue timestamp, unparsed.
  public let issueDate: String?
  /// Source report number, distinct from its part.
  public let number: Int
  /// Source report part, never inferred from a URL.
  public let part: Int?
  /// Every original field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// Original descriptive report type label.
  public let reportType: String?
  /// Source congressional session number.
  public let sessionNumber: Int?
  /// Published text count and link; no document or linked response is fetched.
  public let text: ResourceLink?
  /// Original title when supplied.
  public let title: String?
  /// Open report code, retaining source spelling.
  public let type: String
  /// Original modification timestamp, unparsed.
  public let updateDate: String?

  /// Decodes the original provider object without normalizing its fields.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    associatedBill = try c.decodeIfPresent([CommitteeReportBill].self, forKey: .associatedBill)
    associatedTreaties = try c.decodeIfPresent(
      [CommitteeReportTreaty].self, forKey: .associatedTreaties)
    chamber = try c.decodeIfPresent(String.self, forKey: .chamber)
    citation = try c.decodeIfPresent(String.self, forKey: .citation)
    committees = try c.decodeIfPresent([CommitteeReference].self, forKey: .committees)
    congress = try c.decode(Int.self, forKey: .congress)
    isConferenceReport = try c.decodeIfPresent(Bool.self, forKey: .isConferenceReport)
    issueDate = try c.decodeIfPresent(String.self, forKey: .issueDate)
    number = try c.decode(Int.self, forKey: .number)
    part = try c.decodeIfPresent(Int.self, forKey: .part)
    reportType = try c.decodeIfPresent(String.self, forKey: .reportType)
    sessionNumber = try c.decodeIfPresent(Int.self, forKey: .sessionNumber)
    text = try c.decodeIfPresent(ResourceLink.self, forKey: .text)
    title = try c.decodeIfPresent(String.self, forKey: .title)
    type = try c.decode(String.self, forKey: .type)
    updateDate = try c.decodeIfPresent(String.self, forKey: .updateDate)
  }

  /// Encodes every retained source field.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case associatedBill
    case associatedTreaties
    case chamber
    case citation
    case committees
    case congress
    case isConferenceReport
    case issueDate
    case number
    case part
    case reportType
    case sessionNumber
    case text
    case title
    case type
    case updateDate
  }
}
