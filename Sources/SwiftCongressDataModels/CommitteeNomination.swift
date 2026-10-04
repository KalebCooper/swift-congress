/// A committee's nomination reference, preserving its number and part separately.
public struct CommitteeNomination: Codable, Hashable, Sendable {
  /// Published nomination citation, without reconstruction.
  public let citation: String?
  /// Source Congress number.
  public let congress: Int
  /// Original nomination description.
  public let description: String?
  /// Latest published action, without inferred status.
  public let latestAction: CommitteeNominationAction?
  /// Published civilian and military flags.
  public let nominationType: CommitteeNominationType?
  /// Source nomination number, separate from its part.
  public let number: Int
  /// Source part string, preserving leading zeroes such as 00.
  public let partNumber: String
  /// Every original field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// Original receipt date, unchanged.
  public let receivedDate: String?
  /// Original modification timestamp, unchanged.
  public let updateDate: String?
  /// Published nomination link retained without fetching it.
  public let url: String?

  /// Decodes the original provider record.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    citation = try c.decodeIfPresent(String.self, forKey: .citation)
    congress = try c.decode(Int.self, forKey: .congress)
    description = try c.decodeIfPresent(String.self, forKey: .description)
    latestAction = try c.decodeIfPresent(CommitteeNominationAction.self, forKey: .latestAction)
    nominationType = try c.decodeIfPresent(CommitteeNominationType.self, forKey: .nominationType)
    number = try c.decode(Int.self, forKey: .number)
    partNumber = try c.decode(String.self, forKey: .partNumber)
    receivedDate = try c.decodeIfPresent(String.self, forKey: .receivedDate)
    updateDate = try c.decodeIfPresent(String.self, forKey: .updateDate)
    url = try c.decodeIfPresent(String.self, forKey: .url)
  }

  /// Encodes every retained source field.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case citation
    case congress
    case description
    case latestAction
    case nominationType
    case number
    case partNumber
    case receivedDate
    case updateDate
    case url
  }
}
