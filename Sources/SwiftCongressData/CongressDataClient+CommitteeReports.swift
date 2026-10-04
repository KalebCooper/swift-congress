import SwiftCongressDataModels

extension CongressDataClient {
  /// Creates independent lazy page traversals of a committee's report references.
  ///
  /// Only requested pages are fetched; inconsistent continuation metadata fails before yielding.
  /// - Parameters:
  ///   - identifier: Validated committee chamber and source code.
  ///   - query: Validated page bounds and optional source modification window.
  /// - Returns: Exact page receipts on demand. Iteration throws typed transport, cancellation,
  ///   decoding or invalid-continuation errors.
  public func committeeReportPages(
    for identifier: CommitteeIdentifier, matching query: CommitteeReportQuery
  )
    -> CongressPageSequence<CommitteeReportPage>
  {
    pages(for: .committeeReports(for: identifier, matching: query))
  }

  /// Creates independent lazy traversals preserving report references and source order.
  ///
  /// Only the current page is buffered. Cancellation is checked before every item.
  /// - Parameters:
  ///   - identifier: Validated committee chamber and source code.
  ///   - query: Validated page bounds and optional source modification window.
  /// - Returns: Source items on demand. Iteration throws typed transport, cancellation,
  ///   decoding or invalid-continuation errors.
  public func committeeReports(
    for identifier: CommitteeIdentifier, matching query: CommitteeReportQuery
  )
    -> CongressItemSequence<CommitteeReportPage>
  {
    items(for: .committeeReports(for: identifier, matching: query))
  }
}
