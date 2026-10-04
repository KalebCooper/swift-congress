import SwiftCongressDataModels

extension CongressDataClient {
  /// Creates a lazy geographic member-page traversal with exact response receipts.
  ///
  /// ```swift
  /// let query = try MemberGeographyQuery(scope: .district(district: 0, stateCode: "DC"))
  /// for try await page in client.memberPages(matching: query) {
  ///   print(page.value.members.count)
  /// }
  /// ```
  /// - Parameter query: The validated geographic route and supported source filters.
  /// - Returns: Independent traversals that fetch only on demand. Iteration throws
  ///   `CongressDataError.invalidContinuation` before yielding inconsistent paging metadata,
  ///   or the typed transport, cancellation, or decoding error.
  public func memberPages(matching query: MemberGeographyQuery) -> CongressPageSequence<MemberPage>
  {
    pages(for: .members(matching: query))
  }

  /// Creates a lazy geographic member traversal preserving source order and duplicates.
  ///
  /// Only the current page is buffered; cancellation is checked before buffered items are yielded.
  /// Historical district results may retain a member's later district. No local district filter
  /// or as-of-date inference is applied.
  /// - Parameter query: The validated geographic route and supported source filters.
  /// - Returns: Independent item traversals whose iteration throws
  ///   `CongressDataError.invalidContinuation`, `CongressDataError.transport(.cancelled)`,
  ///   or the typed transport or decoding error.
  public func members(matching query: MemberGeographyQuery) -> CongressItemSequence<MemberPage> {
    items(for: .members(matching: query))
  }
}
