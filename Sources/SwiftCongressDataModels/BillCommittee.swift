/// A bill committee association, not a committee profile or membership roster.
public struct BillCommittee: Codable, Hashable, Sendable {
  /// Source activities in order, retaining duplicates.
  public let activities: [BillCommitteeActivity]?
  /// Open source chamber name.
  public let chamber: String?
  /// Source committee name.
  public let name: String?
  /// Every source field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// Nested associations in source order, without recursive fetching.
  public let subcommittees: [BillSubcommittee]?
  /// Source committee code, unchanged.
  public let systemCode: String?
  /// Open source committee type.
  public let type: String?
  /// Published metadata link; no recursive fetch.
  public let url: String?

  /// Decodes the original provider object.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    activities = try c.decodeIfPresent([BillCommitteeActivity].self, forKey: .activities)
    chamber = try c.decodeIfPresent(String.self, forKey: .chamber)
    name = try c.decodeIfPresent(String.self, forKey: .name)
    subcommittees = try c.decodeIfPresent([BillSubcommittee].self, forKey: .subcommittees)
    systemCode = try c.decodeIfPresent(String.self, forKey: .systemCode)
    type = try c.decodeIfPresent(String.self, forKey: .type)
    url = try c.decodeIfPresent(String.self, forKey: .url)
  }

  /// Encodes all retained source fields.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case activities
    case chamber
    case name
    case subcommittees
    case systemCode
    case type
    case url
  }
}
