#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Page bounds and source date windows for amendments associated with a bill.
public struct BillAmendmentQuery: Hashable, Sendable {
  /// Original lower modification timestamp for source-side validation.
  public let fromDateTime: String?
  /// Validated initial page bounds.
  public let page: CongressQuery
  /// Original upper modification timestamp for source-side validation.
  public let toDateTime: String?

  /// Validates page bounds without interpreting the source timestamp strings.
  /// - Throws: `CongressInputError.invalidQuery` for invalid pagination bounds.
  public init(
    fromDateTime: String? = nil, limit: Int = 20, offset: Int = 0, toDateTime: String? = nil
  ) throws(CongressInputError) {
    self.fromDateTime = fromDateTime
    page = try CongressQuery(limit: limit, offset: offset)
    self.toDateTime = toDateTime
  }

  func path(for identifier: BillSourceIdentifier) -> String {
    var c = URLComponents()
    c.path =
      "/v3/bill/\(identifier.congress)/\(identifier.type.rawValue)/\(identifier.number)/amendments"
    c.queryItems = [.init(name: "format", value: "json")]
    if let fromDateTime { c.queryItems?.append(.init(name: "fromDateTime", value: fromDateTime)) }
    c.queryItems?.append(.init(name: "limit", value: String(page.limit)))
    c.queryItems?.append(.init(name: "offset", value: String(page.offset)))
    if let toDateTime { c.queryItems?.append(.init(name: "toDateTime", value: toDateTime)) }
    return c.percentEncodedPath + "?"
      + (c.percentEncodedQuery ?? "").split(separator: "+", omittingEmptySubsequences: false)
      .joined(separator: "%2B")
  }
}
