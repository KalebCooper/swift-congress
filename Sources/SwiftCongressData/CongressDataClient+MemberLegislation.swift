import SwiftCongressDataModels

extension CongressDataClient {
  /// Creates a lazy traversal of a member's cosponsored legislation records.
  ///
  /// Preserves provider order and amendment rows, buffers only the current page, and never
  /// prefetches. Cancellation and invalid continuation throw `CongressDataError` during iteration.
  /// Exhaustion does not establish historical completeness.
  public func cosponsoredLegislation(
    for identifier: MemberIdentifier, page: CongressQuery = .init()
  )
    -> CongressItemSequence<CosponsoredLegislationPage>
  {
    items(for: .cosponsoredLegislation(for: identifier, page: page))
  }

  /// Creates a lazy traversal of a member's cosponsored legislation pages with exact source receipts.
  ///
  /// Preserves provider order and amendment rows, buffers only the current page, and never
  /// prefetches. Cancellation and invalid continuation throw `CongressDataError` during iteration.
  /// Exhaustion does not establish historical completeness.
  public func cosponsoredLegislationPages(
    for identifier: MemberIdentifier, page: CongressQuery = .init()
  )
    -> CongressPageSequence<CosponsoredLegislationPage>
  {
    pages(for: .cosponsoredLegislation(for: identifier, page: page))
  }

  /// Creates a lazy traversal of a member's sponsored legislation records.
  ///
  /// Preserves provider order and amendment rows, buffers only the current page, and never
  /// prefetches. Cancellation and invalid continuation throw `CongressDataError` during iteration.
  /// Exhaustion does not establish historical completeness.
  public func sponsoredLegislation(for identifier: MemberIdentifier, page: CongressQuery = .init())
    -> CongressItemSequence<SponsoredLegislationPage>
  {
    items(for: .sponsoredLegislation(for: identifier, page: page))
  }

  /// Creates a lazy traversal of a member's sponsored legislation pages with exact source receipts.
  ///
  /// Preserves provider order and amendment rows, buffers only the current page, and never
  /// prefetches. Cancellation and invalid continuation throw `CongressDataError` during iteration.
  /// Exhaustion does not establish historical completeness.
  public func sponsoredLegislationPages(
    for identifier: MemberIdentifier, page: CongressQuery = .init()
  )
    -> CongressPageSequence<SponsoredLegislationPage>
  {
    pages(for: .sponsoredLegislation(for: identifier, page: page))
  }
}
