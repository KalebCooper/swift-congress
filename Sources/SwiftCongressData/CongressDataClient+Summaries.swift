import SwiftCongressDataModels

extension CongressDataClient {
  /// Creates a lazy traversal of a source bill's summary versions in provider order.
  ///
  /// Only the current page is buffered, with no prefetch or version selection. Source HTML is
  /// retained unchanged. Cancellation and HTTP failures throw `CongressDataError` during iteration.
  public func summaries(for identifier: BillSourceIdentifier, page: CongressQuery = .init())
    -> CongressItemSequence<BillSummaryPage>
  {
    items(for: .summaries(for: identifier, page: page))
  }

  /// Creates a lazy summary traversal for a numbered bill through its source identifier.
  public func summaries(for identifier: BillIdentifier, page: CongressQuery = .init())
    -> CongressItemSequence<BillSummaryPage>
  {
    summaries(for: identifier.source, page: page)
  }

  /// Creates a lazy traversal carrying the exact source bytes for each bill summary page.
  ///
  /// Invalid continuation throws `CongressDataError.invalidContinuation` before yielding the
  /// affected page. Counts can change; exhaustion does not promise historical completeness.
  public func summaryPages(for identifier: BillSourceIdentifier, page: CongressQuery = .init())
    -> CongressPageSequence<BillSummaryPage>
  {
    pages(for: .summaries(for: identifier, page: page))
  }

  /// Creates a lazy summary-page traversal for a numbered bill through its source identifier.
  public func summaryPages(for identifier: BillIdentifier, page: CongressQuery = .init())
    -> CongressPageSequence<BillSummaryPage>
  {
    summaryPages(for: identifier.source, page: page)
  }

  /// Creates a lazy publication-feed traversal carrying exact source bytes for each page.
  ///
  /// Omitted date bounds retain the provider's recent-day default. Supply a finite window for a
  /// backfill. Links must preserve route and filters; malformed provider links fail before their
  /// page is yielded with `CongressDataError.invalidContinuation`. No links are rewritten.
  public func summaryUpdatePages(matching query: SummaryQuery)
    -> CongressPageSequence<BillSummaryUpdatePage>
  {
    pages(for: .summaryUpdates(matching: query))
  }

  /// Creates a lazy publication-feed traversal, buffering only the current page.
  ///
  /// Entries retain source order, repeats, and their nested bill. No request occurs until demand;
  /// exhausting the recent-day default does not establish all-time coverage.
  public func summaryUpdates(matching query: SummaryQuery)
    -> CongressItemSequence<BillSummaryUpdatePage>
  {
    items(for: .summaryUpdates(matching: query))
  }
}
