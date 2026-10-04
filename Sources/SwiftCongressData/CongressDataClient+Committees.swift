import SwiftCongressDataModels

extension CongressDataClient {
  /// Retrieves one committee profile with its original history and resource links.
  ///
  /// Related profiles and resources are never fetched automatically.
  /// - Parameters:
  ///   - identifier: Validated chamber and safe source code.
  ///   - congress: Optional positive Congress scope, separate from committee identity.
  /// - Returns: The original detail envelope.
  /// - Throws: Typed invalid-input, transport, cancellation or decoding errors.
  public func committee(_ identifier: CommitteeIdentifier, congress: Int? = nil)
    async throws(CongressDataError) -> CommitteeDetail
  {
    let request: CongressRequest<CommitteeDetail>
    do { request = try .committee(identifier, congress: congress) } catch {
      throw .invalidInput(error)
    }
    return try await value(for: request)
  }

  /// Creates independent lazy committee directory page traversals.
  ///
  /// Inconsistent counts or missing continuations fail before yielding that page.
  /// - Parameter query: Validated directory scope, page bounds and source date filters.
  /// - Returns: Exact page receipts fetched on demand. Iteration throws typed transport,
  ///   cancellation, decoding or invalid-continuation errors.
  public func committeePages(matching query: CommitteeQuery) -> CongressPageSequence<CommitteePage>
  {
    pages(for: .committees(matching: query))
  }

  /// Creates independent lazy committee traversals preserving source order and duplicates.
  ///
  /// Only the current page is buffered. Cancellation is checked before each item.
  /// - Parameter query: Validated directory scope, page bounds and source date filters.
  /// - Returns: Items fetched on demand, with typed transport, cancellation, decoding or
  ///   invalid-continuation errors.
  public func committees(matching query: CommitteeQuery) -> CongressItemSequence<CommitteePage> {
    items(for: .committees(matching: query))
  }
}
