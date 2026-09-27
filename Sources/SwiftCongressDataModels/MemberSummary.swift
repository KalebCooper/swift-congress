/// A member list record retaining every source field.
///
/// The source publishes list terms inside a `terms` object whose `item` array holds the entries;
/// ``terms`` exposes that array and ``rawFields`` keeps the wrapper. `district` is nil when the
/// source omits it, as the recorded senator entries do, and is preserved as zero when the source
/// publishes zero. A record without `bioguideId` or `name` fails its page with a decoding error
/// rather than being skipped.
public struct MemberSummary: Codable, Hashable, Sendable {
  /// The source `bioguideId` value.
  public let bioguideId: String
  /// The source `depiction` value; absent or null values remain nil.
  public let depiction: MemberDepiction?
  /// The source `district` value; absent or null values remain nil.
  public let district: Int?
  /// The source `name` value.
  public let name: String
  /// The source `partyName` value; absent or null values remain nil.
  public let partyName: String?
  /// Every source field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// The source `state` value; absent or null values remain nil.
  public let state: String?
  /// The source `terms.item` entries; an absent or null `terms` or `item` remains nil.
  public let terms: [MemberTermSummary]?
  /// The source `updateDate` value; absent or null values remain nil.
  public let updateDate: String?
  /// The source `url` value; absent or null values remain nil.
  public let url: String?

  /// Decodes the original provider object.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    bioguideId = try c.decode(String.self, forKey: .bioguideId)
    depiction = try c.decodeIfPresent(MemberDepiction.self, forKey: .depiction)
    district = try c.decodeIfPresent(Int.self, forKey: .district)
    name = try c.decode(String.self, forKey: .name)
    partyName = try c.decodeIfPresent(String.self, forKey: .partyName)
    state = try c.decodeIfPresent(String.self, forKey: .state)
    terms = try c.decodeIfPresent(TermList.self, forKey: .terms)?.item
    updateDate = try c.decodeIfPresent(String.self, forKey: .updateDate)
    url = try c.decodeIfPresent(String.self, forKey: .url)
  }

  /// Encodes all retained source fields.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case bioguideId
    case depiction
    case district
    case name
    case partyName
    case state
    case terms
    case updateDate
    case url
  }

  /// The source `terms` wrapper, whose only known key is `item`.
  private struct TermList: Decodable {
    let item: [MemberTermSummary]?
  }
}
