import SwiftCongressDataModels

extension CongressDataClient {
  /// Creates a lazy page traversal with exact source bytes, headers, and status.
  ///
  /// Invalid links or contradictory counts fail before the affected page is yielded with
  /// `CongressDataError.invalidContinuation`. Inclusive counts drive bill cosponsor traversal
  /// when published; active counts remain unchanged. Counts can change between requests.
  public func cosponsorPages(
    for identifier: BillSourceIdentifier, matching query: BillCosponsorQuery
  ) -> CongressPageSequence<BillCosponsorPage> {
    pages(for: .cosponsors(for: identifier, matching: query))
  }

  /// Creates a lazy cosponsor-page traversal for a numbered bill.
  public func cosponsorPages(
    for identifier: BillIdentifier, matching query: BillCosponsorQuery
  ) -> CongressPageSequence<BillCosponsorPage> {
    cosponsorPages(for: identifier.source, matching: query)
  }

  /// Creates a lazy traversal retaining provider order, repeats, and withdrawn cosponsors.
  ///
  /// Only the current page is buffered, with no prefetch. Cancellation and HTTP failures throw
  /// `CongressDataError` during iteration. Cosponsorship does not establish a vote or endorsement
  /// of every provision, and row presence alone does not establish current cosponsor status.
  public func cosponsors(
    for identifier: BillSourceIdentifier, matching query: BillCosponsorQuery
  ) -> CongressItemSequence<BillCosponsorPage> {
    items(for: .cosponsors(for: identifier, matching: query))
  }

  /// Creates a lazy cosponsor traversal for a numbered bill.
  public func cosponsors(
    for identifier: BillIdentifier, matching query: BillCosponsorQuery
  ) -> CongressItemSequence<BillCosponsorPage> {
    cosponsors(for: identifier.source, matching: query)
  }
}
