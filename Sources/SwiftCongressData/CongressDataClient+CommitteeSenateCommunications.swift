import SwiftCongressDataModels

extension CongressDataClient {
  /// Creates independent lazy traversals of a Senate committee's communication references.
  ///
  /// Only requested pages are fetched. Cancellation is checked before each yielded value;
  /// inconsistent continuation metadata fails before yielding its page.
  /// - Parameters:
  ///   - identifier: Validated Senate committee chamber and source code.
  ///   - page: Validated page bounds; no date window or sort is supported.
  /// - Returns: Source page receipts on demand. Iteration reports typed execution errors.
  /// - Throws: `CongressInputError.unsupportedCommitteeResource` before HTTP for House or Joint.
  public func committeeSenateCommunicationPages(
    for identifier: CommitteeIdentifier, page: CongressQuery = .init()
  ) throws(CongressInputError) -> CongressPageSequence<CommitteeSenateCommunicationPage> {
    pages(for: try .committeeSenateCommunications(for: identifier, page: page))
  }

  /// Creates independent lazy traversals of a Senate committee's communication references.
  ///
  /// Only requested pages are fetched. Cancellation is checked before each yielded value;
  /// inconsistent continuation metadata fails before yielding its page.
  /// - Parameters:
  ///   - identifier: Validated Senate committee chamber and source code.
  ///   - page: Validated page bounds; no date window or sort is supported.
  /// - Returns: Source items on demand. Iteration reports typed execution errors.
  /// - Throws: `CongressInputError.unsupportedCommitteeResource` before HTTP for House or Joint.
  public func committeeSenateCommunications(
    for identifier: CommitteeIdentifier, page: CongressQuery = .init()
  ) throws(CongressInputError) -> CongressItemSequence<CommitteeSenateCommunicationPage> {
    items(for: try .committeeSenateCommunications(for: identifier, page: page))
  }
}
