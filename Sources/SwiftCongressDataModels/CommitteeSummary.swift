/// A committee directory record, preserving open source vocabulary.
public struct CommitteeSummary: Codable, Hashable, Sendable {
  /// The open source chamber label.
  public let chamber: String?
  /// The open source type code.
  public let committeeTypeCode: String?
  /// The published directory name.
  public let name: String?
  /// The explicit parent supplied by the source.
  public let parent: CommitteeReference?
  /// Every original source field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// Explicit subcommittee references in source order.
  public let subcommittees: [CommitteeReference]?
  /// The original source system code.
  public let systemCode: String
  /// The unparsed source update timestamp.
  public let updateDate: String?
  /// The original detail link.
  public let url: String?

  /// Decodes the original provider object.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    chamber = try c.decodeIfPresent(String.self, forKey: .chamber)
    committeeTypeCode = try c.decodeIfPresent(String.self, forKey: .committeeTypeCode)
    name = try c.decodeIfPresent(String.self, forKey: .name)
    parent = try c.decodeIfPresent(CommitteeReference.self, forKey: .parent)
    subcommittees = try c.decodeIfPresent([CommitteeReference].self, forKey: .subcommittees)
    systemCode = try c.decode(String.self, forKey: .systemCode)
    updateDate = try c.decodeIfPresent(String.self, forKey: .updateDate)
    url = try c.decodeIfPresent(String.self, forKey: .url)
  }

  /// Encodes every retained source field.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case chamber
    case committeeTypeCode
    case name
    case parent
    case subcommittees
    case systemCode
    case updateDate
    case url
  }
}
