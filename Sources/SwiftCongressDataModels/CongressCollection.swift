/// A Congress.gov list envelope usable by lazy page and item executors.
public protocol CongressCollection: Codable, Sendable {
  /// The records contained in a single page.
  associatedtype Item: Sendable
  /// Records in provider order.
  var items: [Item] { get }
  /// The source pagination object.
  var pagination: Pagination { get }
}
