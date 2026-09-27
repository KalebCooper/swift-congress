/// One text version of a bill, as listed by Congress.gov.
///
/// The provider publishes no version identifier, so this type does not synthesize one or derive a
/// version code from a file name. The date is the source string with its published precision; the
/// provider associates it with an action rather than with printing, and a recorded version publishes
/// it as null. The version name stays the source string.
///
/// ```swift
/// for version in page.textVersions {
///   print(version.type ?? "unnamed", version.date ?? "undated", version.formats?.count ?? 0)
/// }
/// ```
public struct BillTextVersion: Codable, Hashable, Sendable {
  /// The source `date` value, unparsed; absent or null values remain nil.
  public let date: String?
  /// The source `formats` value in provider order; absent or null is nil and a published empty
  /// array is empty.
  public let formats: [BillTextFormat]?
  /// Every source field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// The source `type` value, such as `Enrolled Bill`; absent or null values remain nil.
  public let type: String?

  /// Decodes the original provider object.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    date = try c.decodeIfPresent(String.self, forKey: .date)
    formats = try c.decodeIfPresent([BillTextFormat].self, forKey: .formats)
    type = try c.decodeIfPresent(String.self, forKey: .type)
  }

  /// Encodes all retained source fields.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case date
    case formats
    case type
  }
}
