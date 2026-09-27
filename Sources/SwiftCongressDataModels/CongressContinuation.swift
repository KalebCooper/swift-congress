#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// A pagination failure detected before yielding the affected page.
public enum CongressPaginationError: Error, Hashable, Sendable {
  /// Missing, malformed, inconsistent, or nonprogressing metadata.
  case invalidContinuation
}

/// Pure validation of Congress.gov continuation links and query identity.
public enum CongressContinuation {
  /// Validates the next link without performing I/O.
  ///
  /// Filters and page size must stay unchanged, and offsets must advance by the returned record
  /// count. A ``BillTextVersionPage`` may carry one record beyond the requested limit; its offset
  /// then advances by the limit.
  /// - Throws: `CongressPaginationError.invalidContinuation` before exposing an invalid page.
  public static func next<Page: CongressCollection>(after page: Page, endpoint: Endpoint<Page>)
    throws(CongressPaginationError) -> Endpoint<Page>?
  {
    let allowance = (Page.self as? any CongressPageOverrun.Type)?.pageOverrunAllowance ?? 0
    guard let current = URLComponents(string: "https://api.congress.gov" + endpoint.path),
      let query = parameters(current), let offset = Int(query["offset"] ?? "0"), offset >= 0,
      let limit = Int(query["limit"] ?? "20"), (1...250).contains(limit),
      page.pagination.count >= 0, page.items.count <= limit + allowance,
      offset <= Int.max - min(page.items.count, limit)
    else { throw .invalidContinuation }
    let end = offset + min(page.items.count, limit)
    guard let link = page.pagination.next else {
      guard end >= page.pagination.count else { throw .invalidContinuation }
      return nil
    }
    guard !page.items.isEmpty, end < page.pagination.count,
      let url = URL(string: link), let next = Endpoint<Page>(link: url),
      let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
      var nextQuery = parameters(components),
      components.percentEncodedPath == current.percentEncodedPath,
      Int(nextQuery.removeValue(forKey: "offset") ?? "") == end
    else { throw .invalidContinuation }
    var original = query
    original.removeValue(forKey: "offset")
    guard original == nextQuery else { throw .invalidContinuation }
    return next
  }

  private static func parameters(_ components: URLComponents) -> [String: String]? {
    var values: [String: String] = [:]
    for item in components.queryItems ?? [] {
      guard let value = item.value, values[item.name] == nil else { return nil }
      values[item.name] = value
    }
    if values["format"] == nil { values["format"] = "json" }
    if values["limit"] == nil { values["limit"] = "20" }
    return values
  }
}
