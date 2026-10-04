/// A nested bill subcommittee association, without inferred chamber or parent profile.
public struct BillSubcommittee: Codable, Hashable, Sendable {
  /// Source activities in order, retaining duplicates.
  public let activities: [BillCommitteeActivity]?
  /// Source subcommittee name.
  public let name: String?
  /// Every source field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// Source committee code, unchanged.
  public let systemCode: String?
  /// Published metadata link; no recursive fetch.
  public let url: String?

  /// Decodes the original provider object.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    activities = try c.decodeIfPresent([BillCommitteeActivity].self, forKey: .activities)
    name = try c.decodeIfPresent(String.self, forKey: .name)
    systemCode = try c.decodeIfPresent(String.self, forKey: .systemCode)
    url = try c.decodeIfPresent(String.self, forKey: .url)
  }

  /// Encodes all retained source fields.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case activities
    case name
    case systemCode
    case url
  }
}
