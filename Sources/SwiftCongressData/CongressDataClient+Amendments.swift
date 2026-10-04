import SwiftCongressDataModels

extension CongressDataClient {
  /// Retrieves one amendment response without following targets or resource links.
  /// - Throws: A typed transport, cancellation, or decoding failure.
  public func amendment(_ identifier: AmendmentIdentifier)
    async throws(CongressDataError) -> AmendmentDetail
  {
    try await value(for: .amendment(identifier))
  }

  /// Creates independent lazy bill-amendment page traversals with exact response receipts.
  /// Construction performs no I/O; invalid continuation fails before yielding.
  public func amendmentPages(
    for identifier: BillSourceIdentifier, matching query: BillAmendmentQuery
  )
    -> CongressPageSequence<AmendmentPage>
  {
    pages(for: .amendments(for: identifier, matching: query))
  }

  /// Creates bill-amendment page traversals for a numbered bill.
  public func amendmentPages(for identifier: BillIdentifier, matching query: BillAmendmentQuery)
    -> CongressPageSequence<AmendmentPage>
  {
    amendmentPages(for: identifier.source, matching: query)
  }

  /// Creates independent lazy inventory page traversals with strict continuation.
  public func amendmentPages(matching query: AmendmentQuery) -> CongressPageSequence<AmendmentPage>
  {
    pages(for: .amendments(matching: query))
  }

  /// Creates lazy bill-amendment item traversals preserving source order and duplicates.
  /// Only the current page is buffered; every item checks cancellation.
  public func amendments(for identifier: BillSourceIdentifier, matching query: BillAmendmentQuery)
    -> CongressItemSequence<AmendmentPage>
  {
    items(for: .amendments(for: identifier, matching: query))
  }

  /// Creates bill-amendment item traversals for a numbered bill.
  public func amendments(for identifier: BillIdentifier, matching query: BillAmendmentQuery)
    -> CongressItemSequence<AmendmentPage>
  {
    amendments(for: identifier.source, matching: query)
  }

  /// Creates lazy inventory item traversals with no prefetch and per-item cancellation.
  public func amendments(matching query: AmendmentQuery) -> CongressItemSequence<AmendmentPage> {
    items(for: .amendments(matching: query))
  }
}
