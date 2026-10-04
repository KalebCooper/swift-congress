import SwiftCongressDataModels

extension CongressDataClient {
  /// Creates a lazy page traversal retaining exact response bytes and metadata.
  /// No related URL is fetched automatically.
  /// Invalid continuation fails before yielding its page. Counts may change between requests.
  /// Cancellation and transport failures throw during iteration, with no prefetch.
  public func committeePages(for identifier: BillSourceIdentifier, page: CongressQuery = .init())
    -> CongressPageSequence<BillCommitteePage>
  {
    pages(for: .committees(for: identifier, page: page))
  }

  /// Creates the same lazy traversal for a numbered bill.
  public func committeePages(for identifier: BillIdentifier, page: CongressQuery = .init())
    -> CongressPageSequence<BillCommitteePage>
  {
    committeePages(for: identifier.source, page: page)
  }

  /// Creates a lazy item traversal preserving source order and duplicates.
  /// No related URL is fetched automatically.
  /// Invalid continuation fails before yielding its page. Counts may change between requests.
  /// Cancellation and transport failures throw during iteration, with no prefetch.
  public func committees(for identifier: BillSourceIdentifier, page: CongressQuery = .init())
    -> CongressItemSequence<BillCommitteePage>
  {
    items(for: .committees(for: identifier, page: page))
  }

  /// Creates the same lazy traversal for a numbered bill.
  public func committees(for identifier: BillIdentifier, page: CongressQuery = .init())
    -> CongressItemSequence<BillCommitteePage>
  {
    committees(for: identifier.source, page: page)
  }

  /// Creates a lazy page traversal retaining exact response bytes and metadata.
  /// No related URL is fetched automatically.
  /// Invalid continuation fails before yielding its page. Counts may change between requests.
  /// Cancellation and transport failures throw during iteration, with no prefetch.
  public func relatedBillPages(for identifier: BillSourceIdentifier, page: CongressQuery = .init())
    -> CongressPageSequence<RelatedBillPage>
  {
    pages(for: .relatedBills(for: identifier, page: page))
  }

  /// Creates the same lazy traversal for a numbered bill.
  public func relatedBillPages(for identifier: BillIdentifier, page: CongressQuery = .init())
    -> CongressPageSequence<RelatedBillPage>
  {
    relatedBillPages(for: identifier.source, page: page)
  }

  /// Creates a lazy item traversal preserving source order and duplicates.
  /// No related URL is fetched automatically.
  /// Invalid continuation fails before yielding its page. Counts may change between requests.
  /// Cancellation and transport failures throw during iteration, with no prefetch.
  public func relatedBills(for identifier: BillSourceIdentifier, page: CongressQuery = .init())
    -> CongressItemSequence<RelatedBillPage>
  {
    items(for: .relatedBills(for: identifier, page: page))
  }

  /// Creates the same lazy traversal for a numbered bill.
  public func relatedBills(for identifier: BillIdentifier, page: CongressQuery = .init())
    -> CongressItemSequence<RelatedBillPage>
  {
    relatedBills(for: identifier.source, page: page)
  }

  /// Creates a lazy page traversal retaining exact response bytes and metadata.
  /// Policy-only pages are exposed; raw counts include the separate policy record.
  /// Invalid continuation fails before yielding its page. Counts may change between requests.
  /// Cancellation and transport failures throw during iteration, with no prefetch.
  public func subjectPages(for identifier: BillSourceIdentifier, matching query: BillSubjectQuery)
    -> CongressPageSequence<BillSubjectPage>
  {
    pages(for: .subjects(for: identifier, matching: query))
  }

  /// Creates the same lazy traversal for a numbered bill.
  public func subjectPages(for identifier: BillIdentifier, matching query: BillSubjectQuery)
    -> CongressPageSequence<BillSubjectPage>
  {
    subjectPages(for: identifier.source, matching: query)
  }

  /// Creates a lazy item traversal preserving source order and duplicates.
  /// Only legislative subjects are yielded; policy-only pages advance on item demand.
  /// Invalid continuation fails before yielding its page. Counts may change between requests.
  /// Cancellation and transport failures throw during iteration, with no prefetch.
  public func subjects(for identifier: BillSourceIdentifier, matching query: BillSubjectQuery)
    -> CongressItemSequence<BillSubjectPage>
  {
    items(for: .subjects(for: identifier, matching: query))
  }

  /// Creates the same lazy traversal for a numbered bill.
  public func subjects(for identifier: BillIdentifier, matching query: BillSubjectQuery)
    -> CongressItemSequence<BillSubjectPage>
  {
    subjects(for: identifier.source, matching: query)
  }
}
