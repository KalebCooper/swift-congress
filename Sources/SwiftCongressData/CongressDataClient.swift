#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import HTTPCore
import HTTPTypes
import SwiftCongressDataModels

/// Executes Congress.gov requests through an injected transport.
/// Redirects are refused, credentials are headers, and retries are disabled unless explicitly supplied.
///
/// ```swift
/// let request = CongressRequest.bill(try BillSourceIdentifier(congress: 6, number: "1", type: .houseBill))
/// let response = try await client.value(for: request)
/// ```
public struct CongressDataClient: Sendable {
  /// Required request configuration.
  public let configuration: CongressDataConfiguration
  private let client: HTTPClient

  /// Creates a client with an injected clock and transport.
  /// A retry policy is applied only by HTTPCore; response headers retain quota and Retry-After values.
  public init(
    clock: any Clock<Duration> = ContinuousClock(), configuration: CongressDataConfiguration,
    retryPolicy: RetryPolicy = .disabled, transport: any Transport
  ) {
    self.configuration = configuration
    guard let base = URL(string: "https://api.congress.gov") else {
      preconditionFailure("The fixed Congress.gov origin is a valid URL.")
    }
    client = HTTPClient(
      baseURL: base, clock: clock, redirectPolicy: .never,
      retryPolicy: retryPolicy, transport: transport)
  }

  /// Creates a lazy action-page traversal with exact source receipts.
  public func actionPages(for identifier: BillSourceIdentifier, page: CongressQuery = .init())
    -> CongressPageSequence<BillActionPage>
  { pages(for: .actions(for: identifier, page: page)) }

  /// Creates a lazy action traversal in provider order.
  public func actions(for identifier: BillSourceIdentifier, page: CongressQuery = .init())
    -> CongressItemSequence<BillActionPage>
  { items(for: .actions(for: identifier, page: page)) }

  /// Retrieves a source bill record, retaining its provider envelope.
  /// - Throws: `CongressDataError` for decoding or transport failures.
  public func bill(_ identifier: BillSourceIdentifier) async throws(CongressDataError) -> BillDetail
  {
    try await value(for: .bill(identifier))
  }

  /// Retrieves a numbered bill through the same typed request executor.
  public func bill(_ identifier: BillIdentifier) async throws(CongressDataError) -> BillDetail {
    try await value(for: .bill(identifier))
  }

  /// Creates a lazy bill-page traversal without fetching its first page.
  public func billPages(matching query: BillQuery) -> CongressPageSequence<BillPage> {
    pages(for: .bills(matching: query))
  }

  /// Creates a lazy bill traversal, preserving source order and duplicates.
  public func bills(matching query: BillQuery) -> CongressItemSequence<BillPage> {
    items(for: .bills(matching: query))
  }

  /// Creates a lazy Congress-page traversal across every provider-published era.
  public func congressPages(matching query: CongressQuery = .init()) -> CongressPageSequence<
    CongressPage
  > {
    pages(for: .congresses(matching: query))
  }

  /// Creates a lazy Congress traversal without assuming a current upper bound.
  public func congresses(matching query: CongressQuery = .init()) -> CongressItemSequence<
    CongressPage
  > {
    items(for: .congresses(matching: query))
  }

  /// Creates independent item traversals for a reusable collection request.
  public func items<Page: CongressCollection>(for request: CongressRequest<Page>)
    -> CongressItemSequence<Page>
  {
    CongressItemSequence(pages: pages(for: request))
  }

  /// Retrieves one member record through the typed request executor.
  ///
  /// The response is the provider's current record for the identifier; no freshness or completeness
  /// guarantee is made, and fields the source omits stay absent.
  ///
  /// ```swift
  /// let detail = try await client.member(try MemberIdentifier(rawValue: "L000174"))
  /// ```
  /// - Parameter identifier: The validated member identifier, sent as supplied.
  /// - Returns: The decoded member detail, retaining every source field.
  /// - Throws: `CongressDataError.transport(.cancelled)` when cancelled before or after the
  ///   request, `CongressDataError.transport(_:)` with the HTTP status and headers for a non-success
  ///   response, or `CongressDataError.decoding` when the body is not a member detail.
  public func member(_ identifier: MemberIdentifier) async throws(CongressDataError)
    -> MemberDetail
  {
    try await value(for: .member(identifier))
  }

  /// Creates a lazy member-page traversal without fetching its first page.
  ///
  /// Each page is fetched on demand and carries the exact bytes it was decoded from. Provider
  /// continuation links are followed only when they keep the route, page size, and filters.
  /// Counts may change during traversal; the pages are not a snapshot.
  ///
  /// ```swift
  /// for try await page in client.memberPages(matching: try MemberQuery(scope: .congress(117))) {
  ///   print(page.value.members.count)
  /// }
  /// ```
  /// - Parameter query: The member inventory route, filters, and page bounds.
  /// - Returns: A sequence whose iteration throws `CongressDataError.invalidContinuation` before
  ///   yielding a page with an invalid continuation, or the transport or decoding failure.
  public func memberPages(matching query: MemberQuery) -> CongressPageSequence<MemberPage> {
    pages(for: .members(matching: query))
  }

  /// Creates a lazy member traversal in provider order, preserving duplicates.
  ///
  /// Only the current page is buffered. No page is fetched until the first item is requested, and
  /// nothing implies complete historical membership.
  ///
  /// ```swift
  /// for try await member in client.members(matching: try MemberQuery(scope: .congress(117))) {
  ///   print(member.bioguideId)
  /// }
  /// ```
  /// - Parameter query: The member inventory route, filters, and page bounds.
  /// - Returns: A sequence whose iteration throws `CongressDataError.invalidContinuation`,
  ///   `CongressDataError.transport(.cancelled)`, or the transport or decoding failure.
  public func members(matching query: MemberQuery) -> CongressItemSequence<MemberPage> {
    items(for: .members(matching: query))
  }

  /// Creates independent page traversals; custom endpoint requests yield exactly one page.
  public func pages<Page: CongressCollection>(for request: CongressRequest<Page>)
    -> CongressPageSequence<Page>
  {
    let endpoint: Endpoint<Page>
    let followsLinks: Bool
    switch request.resolution {
    case .collection(let value): endpoint = value; followsLinks = true
    case .endpoint(let value): endpoint = value; followsLinks = false
    }
    let base = client.pages(
      httpRequest(endpoint), as: SourceResponse<Page>.self,
      decode: { response in try Self.decode(response, as: Page.self) },
      next: { page, sent in
        guard followsLinks, let current = Endpoint<Page>(path: sent.path),
          let next = try? CongressContinuation.next(after: page.value.value, endpoint: current)
        else { return nil }
        return .request(httpRequest(next))
      })
    return CongressPageSequence(base: base, endpoint: endpoint, followsLinks: followsLinks)
  }

  /// Retrieves one endpoint with the original bytes, status, and repeated response headers.
  /// - Throws: `CongressDataError` for cancellation, HTTP status, transport, or decoding failure.
  public func response<Value: Decodable & Sendable>(for endpoint: Endpoint<Value>)
    async throws(CongressDataError)
    -> SourceResponse<Value>
  {
    guard !Task.isCancelled else { throw .transport(.cancelled) }
    let response: Response
    do throws(TransportError) { response = try await client.execute(httpRequest(endpoint)) } catch {
      throw .transport(error)
    }
    guard !Task.isCancelled else { throw .transport(.cancelled) }
    do { return try Self.decode(response, as: Value.self) } catch { throw .decoding }
  }

  /// Executes one typed endpoint; this never follows pagination.
  public func send<Value: Decodable & Sendable>(_ endpoint: Endpoint<Value>)
    async throws(CongressDataError) -> Value
  {
    try await response(for: endpoint).value
  }

  /// Executes the first response of an immutable request.
  public func value<Value: Decodable & Sendable>(for request: CongressRequest<Value>)
    async throws(CongressDataError) -> Value
  {
    switch request.resolution {
    case .collection(let endpoint), .endpoint(let endpoint): try await send(endpoint)
    }
  }

  private static func decode<Value: Decodable & Sendable>(_ response: Response, as type: Value.Type)
    throws -> SourceResponse<Value>
  {
    SourceResponse(
      body: response.body,
      headers: response.headers.map { SourceHeader(name: $0.name.rawName, value: $0.value) },
      status: response.status.code, value: try JSONDecoder().decode(type, from: response.body))
  }

  private func httpRequest<Value>(_ endpoint: Endpoint<Value>) -> Request {
    guard let key = HTTPField.Name("X-Api-Key") else {
      preconditionFailure("X-Api-Key is a valid HTTP field.")
    }
    return Request(
      headers: [
        .accept: "application/json", key: configuration.apiKey,
        .userAgent: configuration.userAgent,
      ], path: endpoint.path)
  }
}
