import SwiftCongressDataModels

extension CongressDataClient {
  /// Creates independent lazy traversals of a Senate committee's nomination references.
  ///
  /// Only requested pages are fetched. Cancellation is checked before each yielded value;
  /// inconsistent continuation metadata fails before yielding its page.
  /// - Parameters:
  ///   - identifier: Validated Senate committee chamber and source code.
  ///   - page: Validated page bounds; no date window or sort is supported.
  /// - Returns: Source page receipts on demand. Iteration reports typed execution errors.
  /// - Throws: `CongressInputError.unsupportedCommitteeResource` before HTTP for House or Joint.
  public func committeeNominationPages(
    for identifier: CommitteeIdentifier, page: CongressQuery = .init()
  ) throws(CongressInputError) -> CongressPageSequence<CommitteeNominationPage> {
    pages(for: try .committeeNominations(for: identifier, page: page))
  }

  /// Creates independent lazy traversals of a Senate committee's nomination references.
  ///
  /// Only requested pages are fetched. Cancellation is checked before each yielded value;
  /// inconsistent continuation metadata fails before yielding its page.
  /// - Parameters:
  ///   - identifier: Validated Senate committee chamber and source code.
  ///   - page: Validated page bounds; no date window or sort is supported.
  /// - Returns: Source items on demand. Iteration reports typed execution errors.
  /// - Throws: `CongressInputError.unsupportedCommitteeResource` before HTTP for House or Joint.
  public func committeeNominations(
    for identifier: CommitteeIdentifier, page: CongressQuery = .init()
  ) throws(CongressInputError) -> CongressItemSequence<CommitteeNominationPage> {
    items(for: try .committeeNominations(for: identifier, page: page))
  }
}
