import SwiftCongressDataModels

extension CongressDataClient {
  /// Creates independent lazy traversals of a House committee's communication references.
  ///
  /// Only requested pages are fetched. Cancellation is checked before each yielded value;
  /// inconsistent continuation metadata fails before yielding its page.
  /// - Parameters:
  ///   - identifier: Validated House committee chamber and source code.
  ///   - page: Validated page bounds; no date window or sort is supported.
  /// - Returns: Source page receipts on demand. Iteration reports typed execution errors.
  /// - Throws: `CongressInputError.unsupportedCommitteeResource` before HTTP for Senate or Joint.
  public func committeeHouseCommunicationPages(
    for identifier: CommitteeIdentifier, page: CongressQuery = .init()
  ) throws(CongressInputError) -> CongressPageSequence<CommitteeHouseCommunicationPage> {
    pages(for: try .committeeHouseCommunications(for: identifier, page: page))
  }

  /// Creates independent lazy traversals of a House committee's communication references.
  ///
  /// Only requested pages are fetched. Cancellation is checked before each yielded value;
  /// inconsistent continuation metadata fails before yielding its page.
  /// - Parameters:
  ///   - identifier: Validated House committee chamber and source code.
  ///   - page: Validated page bounds; no date window or sort is supported.
  /// - Returns: Source items on demand. Iteration reports typed execution errors.
  /// - Throws: `CongressInputError.unsupportedCommitteeResource` before HTTP for Senate or Joint.
  public func committeeHouseCommunications(
    for identifier: CommitteeIdentifier, page: CongressQuery = .init()
  ) throws(CongressInputError) -> CongressItemSequence<CommitteeHouseCommunicationPage> {
    items(for: try .committeeHouseCommunications(for: identifier, page: page))
  }
}
