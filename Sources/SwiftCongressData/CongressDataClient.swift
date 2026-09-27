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

  /// Creates a lazy action-page traversal without fetching its first page.
  ///
  /// Each page is fetched on demand and carries the exact bytes it was decoded from. Provider
  /// continuation links are followed only when they keep the route and page size. Actions are the
  /// provider's published history for the record; no completeness guarantee is made.
  ///
  /// ```swift
  /// let identifier = try BillSourceIdentifier(congress: 119, number: "1", type: .houseBill)
  /// for try await page in client.actionPages(for: identifier) {
  ///   print(page.value.actions.count)
  /// }
  /// ```
  /// - Parameters:
  ///   - identifier: The bill record whose actions are listed.
  ///   - page: The page bounds; the default is 20 records from offset zero.
  /// - Returns: A sequence whose iteration throws `CongressDataError.invalidContinuation` before
  ///   yielding a page with an invalid continuation, or the transport or decoding failure.
  public func actionPages(for identifier: BillSourceIdentifier, page: CongressQuery = .init())
    -> CongressPageSequence<BillActionPage>
  { pages(for: .actions(for: identifier, page: page)) }

  /// Creates a lazy action traversal in provider order, preserving duplicates.
  ///
  /// Only the current page is buffered, and no page is fetched until the first action is
  /// requested.
  ///
  /// ```swift
  /// let identifier = try BillSourceIdentifier(congress: 119, number: "1", type: .houseBill)
  /// for try await action in client.actions(for: identifier) {
  ///   print(action.actionDate ?? "", action.text ?? "")
  /// }
  /// ```
  /// - Parameters:
  ///   - identifier: The bill record whose actions are listed.
  ///   - page: The initial page bounds; the default is 20 records from offset zero.
  /// - Returns: A sequence whose iteration throws `CongressDataError.invalidContinuation`,
  ///   `CongressDataError.transport(.cancelled)`, or the transport or decoding failure.
  public func actions(for identifier: BillSourceIdentifier, page: CongressQuery = .init())
    -> CongressItemSequence<BillActionPage>
  { items(for: .actions(for: identifier, page: page)) }

  /// Retrieves a source bill record, retaining its provider envelope.
  ///
  /// Use this overload for early records whose numbers may be surrogates; no official bill number
  /// is asserted. The response is the provider's current record, and fields the source omits stay
  /// absent.
  ///
  /// ```swift
  /// let detail = try await client.bill(
  ///   try BillSourceIdentifier(congress: 6, number: "1", type: .houseBill))
  /// ```
  /// - Parameter identifier: The validated source key, sent as normalized.
  /// - Returns: The decoded bill detail, retaining every source field.
  /// - Throws: `CongressDataError.transport(.cancelled)` when cancelled before or after the
  ///   request, `CongressDataError.transport(_:)` with the HTTP status and headers for a non-success
  ///   response, or `CongressDataError.decoding` when the body is not a bill detail.
  public func bill(_ identifier: BillSourceIdentifier) async throws(CongressDataError) -> BillDetail
  {
    try await value(for: .bill(identifier))
  }

  /// Retrieves a numbered bill through the same typed request executor.
  ///
  /// The request is the one its source key produces. The response is the provider's current
  /// record, and fields the source omits stay absent.
  ///
  /// ```swift
  /// let detail = try await client.bill(
  ///   try BillIdentifier(congress: 119, number: "1", type: .houseBill))
  /// ```
  /// - Parameter identifier: The validated numbered bill identity.
  /// - Returns: The decoded bill detail, retaining every source field.
  /// - Throws: `CongressDataError.transport(.cancelled)` when cancelled before or after the
  ///   request, `CongressDataError.transport(_:)` with the HTTP status and headers for a non-success
  ///   response, or `CongressDataError.decoding` when the body is not a bill detail.
  public func bill(_ identifier: BillIdentifier) async throws(CongressDataError) -> BillDetail {
    try await value(for: .bill(identifier))
  }

  /// Creates a lazy bill-page traversal without fetching its first page.
  ///
  /// Each page is fetched on demand and carries the exact bytes it was decoded from. Provider
  /// continuation links are followed only when they keep the route, page size, and filters.
  /// Counts may change during traversal; the pages are not a snapshot.
  ///
  /// ```swift
  /// for try await page in client.billPages(matching: try BillQuery(congress: 6, limit: 2)) {
  ///   print(page.value.bills.count)
  /// }
  /// ```
  /// - Parameter query: The bill inventory scope, filters, sort, and page bounds.
  /// - Returns: A sequence whose iteration throws `CongressDataError.invalidContinuation` before
  ///   yielding a page with an invalid continuation, or the transport or decoding failure.
  public func billPages(matching query: BillQuery) -> CongressPageSequence<BillPage> {
    pages(for: .bills(matching: query))
  }

  /// Creates a lazy bill traversal, preserving source order and duplicates.
  ///
  /// Only the current page is buffered. No page is fetched until the first bill is requested, and
  /// nothing implies a complete historical collection.
  ///
  /// ```swift
  /// for try await bill in client.bills(matching: try BillQuery(congress: 6, limit: 2)) {
  ///   print(bill.number, bill.title)
  /// }
  /// ```
  /// - Parameter query: The bill inventory scope, filters, sort, and page bounds.
  /// - Returns: A sequence whose iteration throws `CongressDataError.invalidContinuation`,
  ///   `CongressDataError.transport(.cancelled)`, or the transport or decoding failure.
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

  /// Creates a lazy text-version page traversal for a source bill record without fetching.
  ///
  /// Each page is fetched on demand and carries the exact bytes it was decoded from. Provider
  /// continuation links are followed only when they keep the route and page size. Format links are
  /// supplied metadata; no request is sent to them. A full traversal can yield the provider's
  /// repeated version more than once, and versions are never de-duplicated. No completeness
  /// guarantee is made.
  ///
  /// ```swift
  /// let identifier = try BillSourceIdentifier(congress: 119, number: "1", type: .houseBill)
  /// for try await page in client.textVersionPages(for: identifier) {
  ///   print(page.value.textVersions.count)
  /// }
  /// ```
  /// - Parameters:
  ///   - identifier: The bill record whose text versions are listed.
  ///   - page: The page bounds; the default is 20 records from offset zero.
  /// - Returns: A sequence whose iteration throws `CongressDataError.invalidContinuation` before
  ///   yielding a page with an invalid continuation, `CongressDataError.transport(_:)` with the
  ///   HTTP status and headers for a non-success response, or `CongressDataError.decoding`.
  public func textVersionPages(
    for identifier: BillSourceIdentifier, page: CongressQuery = .init()
  ) -> CongressPageSequence<BillTextVersionPage> {
    pages(for: .textVersions(for: identifier, page: page))
  }

  /// Creates a lazy text-version page traversal for a numbered bill without fetching.
  ///
  /// The request is the one its source key produces. Format links are supplied metadata; no
  /// request is sent to them. A full traversal can yield the provider's repeated version more than
  /// once, and versions are never de-duplicated.
  ///
  /// ```swift
  /// let identifier = try BillIdentifier(congress: 119, number: "1", type: .houseBill)
  /// for try await page in client.textVersionPages(for: identifier) {
  ///   print(page.status, page.value.textVersions.count)
  /// }
  /// ```
  /// - Parameters:
  ///   - identifier: The validated numbered bill identity.
  ///   - page: The page bounds; the default is 20 records from offset zero.
  /// - Returns: A sequence whose iteration throws `CongressDataError.invalidContinuation` before
  ///   yielding a page with an invalid continuation, `CongressDataError.transport(_:)` with the
  ///   HTTP status and headers for a non-success response, or `CongressDataError.decoding`.
  public func textVersionPages(for identifier: BillIdentifier, page: CongressQuery = .init())
    -> CongressPageSequence<BillTextVersionPage>
  {
    pages(for: .textVersions(for: identifier, page: page))
  }

  /// Creates a lazy text-version traversal for a source bill record in provider order.
  ///
  /// Only the current page is buffered, and no page is fetched until the first version is
  /// requested. A full traversal can yield the provider's repeated version more than once;
  /// versions are never de-duplicated. An empty inventory ends only after a successful response.
  ///
  /// ```swift
  /// let identifier = try BillSourceIdentifier(congress: 119, number: "1", type: .houseBill)
  /// for try await version in client.textVersions(for: identifier) {
  ///   print(version.type ?? "", version.date ?? "")
  /// }
  /// ```
  /// - Parameters:
  ///   - identifier: The bill record whose text versions are listed.
  ///   - page: The initial page bounds; the default is 20 records from offset zero.
  /// - Returns: A sequence whose iteration throws `CongressDataError.invalidContinuation`,
  ///   `CongressDataError.transport(.cancelled)`, `CongressDataError.transport(_:)` for a
  ///   non-success response, or `CongressDataError.decoding`.
  public func textVersions(for identifier: BillSourceIdentifier, page: CongressQuery = .init())
    -> CongressItemSequence<BillTextVersionPage>
  {
    items(for: .textVersions(for: identifier, page: page))
  }

  /// Creates a lazy text-version traversal for a numbered bill in provider order.
  ///
  /// The request is the one its source key produces. A full traversal can yield the provider's
  /// repeated version more than once; versions are never de-duplicated, and format links are
  /// never fetched.
  ///
  /// ```swift
  /// let identifier = try BillIdentifier(congress: 119, number: "1", type: .houseBill)
  /// for try await version in client.textVersions(for: identifier) {
  ///   print(version.formats?.compactMap(\.url) ?? [])
  /// }
  /// ```
  /// - Parameters:
  ///   - identifier: The validated numbered bill identity.
  ///   - page: The initial page bounds; the default is 20 records from offset zero.
  /// - Returns: A sequence whose iteration throws `CongressDataError.invalidContinuation`,
  ///   `CongressDataError.transport(.cancelled)`, `CongressDataError.transport(_:)` for a
  ///   non-success response, or `CongressDataError.decoding`.
  public func textVersions(for identifier: BillIdentifier, page: CongressQuery = .init())
    -> CongressItemSequence<BillTextVersionPage>
  {
    items(for: .textVersions(for: identifier, page: page))
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
