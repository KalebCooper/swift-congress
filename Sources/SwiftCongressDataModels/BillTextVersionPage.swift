/// The BillTextVersionPage response as published by Congress.gov.
///
/// Versions keep provider order and repeats. The recorded pages with a `next` link each carried one
/// version beyond the requested limit, identical to the only version on the recorded page at offset
/// 5; the page at offset 4 is not recorded. Continuation therefore accepts at most one version
/// beyond the limit on this page type: a page that carries the extra version advances the offset by
/// the requested limit, and any other page by its returned count. A page that exceeds the limit by
/// more than one fails before yielding. Items are never de-duplicated, so a traversal can yield the
/// same version more than once.
///
/// ```swift
/// let page = try JSONDecoder().decode(BillTextVersionPage.self, from: data)
/// print(page.pagination.count, page.textVersions.count)
/// ```
public struct BillTextVersionPage: Codable, Hashable, Sendable {
  /// The source `pagination` value.
  public let pagination: Pagination
  /// Every source field, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// The source `request` value; absent or null values remain nil.
  public let request: JSONValue?
  /// The source `textVersions` value.
  public let textVersions: [BillTextVersion]

  /// Decodes the original provider object.
  public init(from decoder: any Decoder) throws {
    rawFields = try [String: JSONValue](from: decoder)
    let c = try decoder.container(keyedBy: CodingKeys.self)
    pagination = try c.decode(Pagination.self, forKey: .pagination)
    request = try c.decodeIfPresent(JSONValue.self, forKey: .request)
    textVersions = try c.decode([BillTextVersion].self, forKey: .textVersions)
  }

  /// Encodes all retained source fields.
  public func encode(to encoder: any Encoder) throws { try rawFields.encode(to: encoder) }

  private enum CodingKeys: String, CodingKey {
    case pagination
    case request
    case textVersions
  }
}

extension BillTextVersionPage: CongressCollection {
  /// Records in source order without local filtering or de-duplication.
  public var items: [BillTextVersion] { textVersions }
}

extension BillTextVersionPage: CongressPageOverrun {
  static var pageOverrunAllowance: Int { 1 }
}
