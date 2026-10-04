import SwiftCongressDataModels

extension CongressDataClient {
  /// Retrieves all report parts in one response without following resource links.
  /// - Throws: A typed transport, cancellation, or decoding failure.
  public func committeeReport(_ identifier: CommitteeReportIdentifier)
    async throws(CongressDataError) -> CommitteeReportDetail
  {
    try await value(for: .committeeReport(identifier))
  }

  /// Creates independent lazy inventory traversals with exact response receipts.
  /// Invalid continuations fail before yielding; construction performs no I/O.
  public func committeeReportPages(matching query: CommitteeReportInventoryQuery)
    -> CongressPageSequence<CommitteeReportPage>
  {
    pages(for: .committeeReports(matching: query))
  }

  /// Creates lazy item traversals preserving inventory order and duplicate report parts.
  /// Buffers only the current page and checks cancellation before every item.
  public func committeeReports(matching query: CommitteeReportInventoryQuery)
    -> CongressItemSequence<CommitteeReportPage>
  {
    items(for: .committeeReports(matching: query))
  }

  /// Creates independent, strictly paginated traversals of report text metadata.
  /// Each receipt retains its exact response bytes. No format link is fetched.
  public func committeeReportTextPages(
    for identifier: CommitteeReportIdentifier, page: CongressQuery = .init()
  ) -> CongressPageSequence<CommitteeReportTextPage> {
    pages(for: .textVersions(for: identifier, page: page))
  }

  /// Creates lazy text-record traversals with current-page buffering and cancellation checks.
  /// Source format order and open errata strings remain unchanged.
  public func committeeReportTextVersions(
    for identifier: CommitteeReportIdentifier, page: CongressQuery = .init()
  ) -> CongressItemSequence<CommitteeReportTextPage> {
    items(for: .textVersions(for: identifier, page: page))
  }
}
