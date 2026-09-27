/// A Congress.gov list envelope usable by lazy page and item executors.
public protocol CongressCollection: Codable, Sendable {
  /// The records contained in a single page.
  associatedtype Item: Sendable
  /// Records in provider order.
  var items: [Item] { get }
  /// The source pagination object.
  var pagination: Pagination { get }
}

/// A collection whose recorded pages can carry records beyond the requested page size.
///
/// Continuation accepts up to `pageOverrunAllowance` extra records on a page. A page at or over the
/// requested limit advances the offset by the limit, and any other page by its returned count.
/// Collections without this conformance allow none.
protocol CongressPageOverrun {
  /// The number of records a page may carry beyond its requested limit.
  static var pageOverrunAllowance: Int { get }
}
