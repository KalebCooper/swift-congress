import SwiftCongressDataModels

extension CongressDataClient {
  /// Retrieves one CRS report detail and its supplied metadata links.
  ///
  /// Format assets and related materials are never fetched automatically.
  /// - Parameter identifier: A validated report path component.
  /// - Returns: The original detail envelope.
  /// - Throws: A typed transport, cancellation, or decoding error.
  public func crsReport(_ identifier: CRSReportIdentifier) async throws(CongressDataError)
    -> CRSReportDetail
  {
    try await value(for: .crsReport(identifier))
  }

  /// Creates independent lazy page traversals with exact response receipts.
  ///
  /// ```swift
  /// for try await page in client.crsReportPages(matching: try CRSReportQuery(limit: 5)) {
  ///   print(page.value.reports.count)
  /// }
  /// ```
  /// - Parameter query: Validated page bounds and unchanged source date filters.
  /// - Returns: Pages fetched on demand. Iteration throws typed transport, cancellation,
  ///   decoding, or invalid-continuation errors before yielding an inconsistent page.
  public func crsReportPages(matching query: CRSReportQuery) -> CongressPageSequence<CRSReportPage>
  {
    pages(for: .crsReports(matching: query))
  }

  /// Creates lazy report-summary traversals preserving source order and duplicates.
  ///
  /// Only the current page is buffered; cancellation is checked before each item.
  /// - Parameter query: Validated page bounds and unchanged source date filters.
  /// - Returns: Independent item traversals with typed transport, cancellation,
  ///   decoding, or invalid-continuation errors.
  public func crsReports(matching query: CRSReportQuery) -> CongressItemSequence<CRSReportPage> {
    items(for: .crsReports(matching: query))
  }
}
