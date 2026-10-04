import SwiftCongressDataModels

extension CongressDataClient {
  /// Retrieves the originating bill detail for a public or private law number.
  ///
  /// The response retains the bill's identity and source law citations. No second request is
  /// made to the bill URL, and the law number is never treated as the bill number.
  /// - Parameter identifier: The validated Congress, category, and law number.
  /// - Returns: The provider's bill detail envelope.
  /// - Throws: `CongressDataError` for cancellation, transport, HTTP status, or decoding failure.
  public func law(_ identifier: LawIdentifier) async throws(CongressDataError) -> BillDetail {
    try await value(for: .law(identifier))
  }

  /// Creates a lazy traversal of bills in a law inventory with original response receipts.
  ///
  /// Pages are fetched only on demand. Invalid continuation links or counts fail before the
  /// affected page is yielded. Counts may change during traversal; this is not a snapshot.
  /// - Parameter query: The Congress, optional law category, and initial page bounds.
  /// - Returns: A sequence whose iteration throws `CongressDataError` for invalid continuation,
  ///   cancellation, transport, HTTP status, or decoding failure.
  public func lawPages(matching query: LawQuery) -> CongressPageSequence<BillPage> {
    pages(for: .laws(matching: query))
  }

  /// Creates a lazy traversal of the originating bills, preserving source order and duplicates.
  ///
  /// Only the current page is buffered, with no prefetch. Bill law citations are source metadata;
  /// an inventory response does not establish historical completeness or trigger extra requests.
  /// - Parameter query: The Congress, optional law category, and initial page bounds.
  /// - Returns: A sequence whose iteration throws `CongressDataError` for invalid continuation,
  ///   cancellation, transport, HTTP status, or decoding failure.
  public func laws(matching query: LawQuery) -> CongressItemSequence<BillPage> {
    items(for: .laws(matching: query))
  }
}
