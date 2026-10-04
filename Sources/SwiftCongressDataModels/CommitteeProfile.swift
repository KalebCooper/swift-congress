/// A committee profile without inferred names, chamber or relationships.
public struct CommitteeProfile: Codable, Hashable, Sendable {
  /// Published bill count and link.
  public let bills: ResourceLink?
  /// The source website string; never fetched automatically.
  public let committeeWebsiteUrl: String?
  /// Published communication count and link.
  public let communications: ResourceLink?
  /// History entries in their original order.
  public let history: [CommitteeHistory]?
  /// The provider's current-status flag, not a historical membership assertion.
  public let isCurrent: Bool?
  /// Published nomination count and link.
  public let nominations: ResourceLink?
  /// The explicit parent supplied by the source.
  public let parent: CommitteeReference?
  /// Every original source field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// Published report count and link.
  public let reports: ResourceLink?
  /// Explicit subcommittee references in source order.
  public let subcommittees: [CommitteeReference]?
  /// The original committee system code.
  public let systemCode: String
  /// The open source committee type.
  public let type: String?
  /// The unparsed source update timestamp.
  public let updateDate: String?

  /// Decodes the original provider object.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    bills = try c.decodeIfPresent(ResourceLink.self, forKey: .bills)
    committeeWebsiteUrl = try c.decodeIfPresent(String.self, forKey: .committeeWebsiteUrl)
    communications = try c.decodeIfPresent(ResourceLink.self, forKey: .communications)
    history = try c.decodeIfPresent([CommitteeHistory].self, forKey: .history)
    isCurrent = try c.decodeIfPresent(Bool.self, forKey: .isCurrent)
    nominations = try c.decodeIfPresent(ResourceLink.self, forKey: .nominations)
    parent = try c.decodeIfPresent(CommitteeReference.self, forKey: .parent)
    reports = try c.decodeIfPresent(ResourceLink.self, forKey: .reports)
    subcommittees = try c.decodeIfPresent([CommitteeReference].self, forKey: .subcommittees)
    systemCode = try c.decode(String.self, forKey: .systemCode)
    type = try c.decodeIfPresent(String.self, forKey: .type)
    updateDate = try c.decodeIfPresent(String.self, forKey: .updateDate)
  }

  /// Encodes every retained source field.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case bills
    case committeeWebsiteUrl
    case communications
    case history
    case isCurrent
    case nominations
    case parent
    case reports
    case subcommittees
    case systemCode
    case type
    case updateDate
  }
}
