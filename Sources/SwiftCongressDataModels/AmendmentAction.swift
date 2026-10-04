/// Published amendment action metadata, distinct from bill action semantics.
public struct AmendmentAction: Codable, Hashable, Sendable {
  /// Original action date, unparsed.
  public let actionDate: String?
  /// Original action time, unparsed.
  public let actionTime: String?
  /// Original links in provider order, including vote references.
  public let links: [AmendmentActionLink]?
  /// Every original field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// Original action description, without deriving an outcome.
  public let text: String?

  /// Decodes the original provider object without normalizing its fields.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    actionDate = try c.decodeIfPresent(String.self, forKey: .actionDate)
    actionTime = try c.decodeIfPresent(String.self, forKey: .actionTime)
    links = try c.decodeIfPresent([AmendmentActionLink].self, forKey: .links)
    text = try c.decodeIfPresent(String.self, forKey: .text)
  }

  /// Encodes every retained source field.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case actionDate
    case actionTime
    case links
    case text
  }
}
