/// An amended treaty target, independent of any bill or amendment target.
public struct AmendmentTreaty: Codable, Hashable, Sendable {
  /// Original Congress number.
  public let congress: Int
  /// Every original field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// Original integer treatyNumber, without renaming the source field.
  public let treatyNumber: Int
  /// Original treaty URL, without automatic traversal.
  public let url: String?

  /// Decodes the original provider object without normalizing its fields.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    congress = try c.decode(Int.self, forKey: .congress)
    treatyNumber = try c.decode(Int.self, forKey: .treatyNumber)
    url = try c.decodeIfPresent(String.self, forKey: .url)
  }

  /// Encodes every retained source field.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case congress
    case treatyNumber
    case url
  }
}
