import HTTPCore
import SwiftCongressDataModels

/// Independent demand-driven pages with the exact bytes behind each decoded envelope.
/// Construction sends nothing. Invalid continuation ends iteration before the page is yielded.
public struct CongressPageSequence<Page: CongressCollection>: AsyncSequence, Sendable {
  /// One decoded page and its source receipt.
  public typealias Element = SourceResponse<Page>
  /// The service execution failure.
  public typealias Failure = CongressDataError

  /// A traversal with its own position and terminal state.
  public struct Iterator: AsyncIteratorProtocol {
    /// One page receipt.
    public typealias Element = SourceResponse<Page>
    /// The service execution failure.
    public typealias Failure = CongressDataError
    private var base: PageSequence<SourceResponse<Page>>.Iterator
    private var endpoint: Endpoint<Page>?
    private let followsLinks: Bool

    init(
      base: PageSequence<SourceResponse<Page>>.Iterator, endpoint: Endpoint<Page>,
      followsLinks: Bool
    ) {
      self.base = base; self.endpoint = endpoint; self.followsLinks = followsLinks
    }

    /// Fetches one page, validates its continuation, and returns its original response.
    /// - Throws: `CongressDataError.invalidContinuation` or a decoding or transport failure.
    public mutating func next(isolation actor: isolated (any Actor)? = #isolation)
      async throws(CongressDataError) -> Element?
    {
      guard let current = endpoint else { return nil }
      endpoint = nil
      guard !Task.isCancelled else { throw .transport(.cancelled) }
      let response: Element
      do throws(TransportError) {
        guard let page = try await base.next(isolation: actor) else { return nil }
        response = page.value
      } catch { throw .mapped(error) }
      guard !Task.isCancelled else { throw .transport(.cancelled) }
      if followsLinks {
        do {
          endpoint = try CongressContinuation.next(after: response.value, endpoint: current)
        } catch { throw .invalidContinuation }
      }
      return response
    }
  }

  private let base: PageSequence<SourceResponse<Page>>
  private let endpoint: Endpoint<Page>
  private let followsLinks: Bool
  init(base: PageSequence<SourceResponse<Page>>, endpoint: Endpoint<Page>, followsLinks: Bool) {
    self.base = base; self.endpoint = endpoint; self.followsLinks = followsLinks
  }

  /// Creates a fresh traversal without fetching or prefetching.
  public func makeAsyncIterator() -> Iterator {
    Iterator(base: base.makeAsyncIterator(), endpoint: endpoint, followsLinks: followsLinks)
  }
}

/// Records in source order, buffering only the current page and checking cancellation per item.
public struct CongressItemSequence<Page: CongressCollection>: AsyncSequence, Sendable {
  /// One source record.
  public typealias Element = Page.Item
  /// The service execution failure.
  public typealias Failure = CongressDataError

  /// An independent item traversal.
  public struct Iterator: AsyncIteratorProtocol {
    /// One source record.
    public typealias Element = Page.Item
    /// The service execution failure.
    public typealias Failure = CongressDataError
    private var buffer: ArraySlice<Element> = []
    private var finished = false
    private var pages: CongressPageSequence<Page>.Iterator
    init(pages: CongressPageSequence<Page>.Iterator) { self.pages = pages }

    /// Returns a buffered item before fetching another page; failures end this iterator.
    public mutating func next(isolation actor: isolated (any Actor)? = #isolation)
      async throws(CongressDataError) -> Element?
    {
      guard !finished else { return nil }
      finished = true
      guard !Task.isCancelled else { buffer = []; throw .transport(.cancelled) }
      while buffer.isEmpty {
        guard let page = try await pages.next(isolation: actor) else { return nil }
        buffer = page.value.items[...]
      }
      guard !Task.isCancelled else { buffer = []; throw .transport(.cancelled) }
      finished = false
      return buffer.popFirst()
    }
  }

  private let pages: CongressPageSequence<Page>
  init(pages: CongressPageSequence<Page>) { self.pages = pages }
  /// Creates a fresh item traversal without fetching.
  public func makeAsyncIterator() -> Iterator { Iterator(pages: pages.makeAsyncIterator()) }
}
