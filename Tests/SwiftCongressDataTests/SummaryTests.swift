#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import HTTPCore
import HTTPTesting
import HTTPTypes
import SwiftCongressData
import SwiftCongressDataModels
import SwiftCongressDataTestSupport
import Testing

extension CongressRequest where Response == BillSummaryPage {
  static var summaryConsumerExample: Self {
    get throws {
      try .summaries(
        for: BillIdentifier(congress: 119, number: "1", type: .houseBill),
        page: CongressQuery(limit: 2))
    }
  }
}

extension CongressRequest where Response == BillSummaryUpdatePage {
  static var summaryFeedConsumerExample: Self {
    get throws { .summaryUpdates(matching: try SummaryTests.feedQuery()) }
  }
}

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct SummaryTests {
  @Test("All bill summary execution levels compile and retain one response")
  func allBillSummaryExecutionLevelsCompileAndRetainOneResponse() async throws {
    let bytes = try Fixture.bill119_summaries_first.data()
    let mock = MockTransport(
      results: Array(repeating: .success(Response(body: bytes, status: .ok)), count: 9))
    let client = client(mock)
    let numbered = try BillIdentifier(congress: 119, number: "1", type: .houseBill)
    let bounds = try CongressQuery(limit: 2)
    let stored = CongressRequest.summaries(for: numbered, page: bounds)
    let expected = try await client.value(for: stored)
    #expect(try await client.value(for: .summaryConsumerExample) == expected)
    #expect(try await client.value(for: .summaries(for: numbered.source, page: bounds)) == expected)
    #expect(try await client.send(.summaries(for: numbered, page: bounds)) == expected)
    var pages = client.summaryPages(for: numbered, page: bounds).makeAsyncIterator()
    #expect(try await pages.next()?.value == expected)
    var items = client.summaries(for: numbered, page: bounds).makeAsyncIterator()
    #expect(try await items.next() == expected.items.first)
    var sourceItems = client.summaries(for: numbered.source, page: bounds).makeAsyncIterator()
    #expect(try await sourceItems.next() == expected.items.first)
    var custom = client.pages(
      for: CongressRequest(endpoint: .summaries(for: numbered, page: bounds))
    ).makeAsyncIterator()
    #expect(try await custom.next()?.value == expected)
    #expect(try await custom.next() == nil)
    struct Consumer: Decodable, Sendable { let pagination: Pagination }
    let endpoint = try #require(
      Endpoint<Consumer>(path: Endpoint.summaries(for: numbered, page: bounds).path))
    #expect(try await client.send(endpoint).pagination.count == 5)
    #expect(mock.requests.count == 9)
  }

  @Test("All summary feed execution levels compile and retain one response")
  func allSummaryFeedExecutionLevelsCompileAndRetainOneResponse() async throws {
    let bytes = try Fixture.summary_updates_window.data()
    let mock = MockTransport(
      results: Array(repeating: .success(Response(body: bytes, status: .ok)), count: 8))
    let client = client(mock)
    let query = try Self.feedQuery()
    let stored = CongressRequest.summaryUpdates(matching: query)
    let expected = try await client.value(for: stored)
    #expect(try await client.value(for: .summaryUpdates(matching: query)) == expected)
    #expect(try await client.value(for: .summaryFeedConsumerExample) == expected)
    #expect(try await client.send(.summaryUpdates(matching: query)) == expected)
    var pages = client.summaryUpdatePages(matching: query).makeAsyncIterator()
    #expect(try await pages.next()?.value == expected)
    var items = client.summaryUpdates(matching: query).makeAsyncIterator()
    #expect(try await items.next() == expected.items.first)
    var custom = client.pages(for: CongressRequest(endpoint: .summaryUpdates(matching: query)))
      .makeAsyncIterator()
    #expect(try await custom.next()?.value == expected)
    #expect(try await custom.next() == nil)
    struct Consumer: Decodable, Sendable { let summaries: [BillSummaryUpdate] }
    let endpoint = try #require(
      Endpoint<Consumer>(path: Endpoint.summaryUpdates(matching: query).path))
    #expect(try await client.send(endpoint).summaries == expected.summaries)
    #expect(mock.requests.count == 8)
  }

  @Test("Both summary collections buffer lazily and keep iterators independent")
  func bothSummaryCollectionsBufferLazilyAndKeepIteratorsIndependent() async throws {
    try await buffering(try billRequest(), fixture: .bill119_summaries_first)
    try await buffering(
      .summaryUpdates(matching: try Self.feedQuery()), fixture: .summary_updates_window)
  }

  @Test("Both summary collections cancel before HTTP and while buffered")
  func bothSummaryCollectionsCancelBeforeHTTPAndWhileBuffered() async throws {
    try await cancellation(try billRequest(), fixture: .bill119_summaries_first)
    try await cancellation(
      .summaryUpdates(matching: try Self.feedQuery()), fixture: .summary_updates_window)
  }

  @Test("Both summary collections preserve later typed failures and quota headers")
  func bothSummaryCollectionsPreserveLaterTypedFailuresAndQuotaHeaders() async throws {
    try await laterFailure(try billRequest(), fixture: .bill119_summaries_first)
    try await laterFailure(
      .summaryUpdates(matching: try Self.feedQuery()), fixture: .summary_updates_window)
  }

  @Test(
    "Invalid summary continuations fail before any record is yielded",
    arguments: [
      "origin", "path", "identity", "credentials", "duplicate", "repeated", "skipped",
      "malformed", "missing", "limit", "filter", "overrun",
    ])
  func invalidSummaryContinuationsFailBeforeAnyRecordIsYielded(mutation: String) async throws {
    try await invalidContinuation(
      try billRequest(), fixture: .bill119_summaries_first, mutation: mutation)
    try await invalidContinuation(
      .summaryUpdates(matching: try Self.feedQuery()),
      fixture: .summary_updates_window, mutation: mutation)
  }

  @Test("Recorded bill summary links traverse all versions and exact receipts")
  func recordedBillSummaryLinksTraverseAllVersionsAndExactReceipts() async throws {
    let fixtures: [Fixture] = [
      .bill119_summaries_first, .bill119_summaries_next, .bill119_summaries_terminal,
    ]
    let bodies = try fixtures.map { try $0.data() }
    let paths = [
      "/v3/bill/119/hr/1/summaries?format=json&limit=2&offset=0",
      "/v3/bill/119/hr/1/summaries?offset=2&limit=2&format=json",
      "/v3/bill/119/hr/1/summaries?offset=4&limit=2&format=json",
    ]
    let recorded = Dictionary(uniqueKeysWithValues: zip(paths, bodies))
    let mock = MockTransport()
    mock.setHandler(forPath: "/v3/bill/119/hr/1/summaries") { request in
      guard let path = request.path, let body = recorded[path] else {
        return .success(MockTransport.Answer(Response(status: .notFound)))
      }
      return .success(MockTransport.Answer(Response(body: body, status: .ok)))
    }
    var pages = client(mock).pages(for: try billRequest()).makeAsyncIterator()
    for body in bodies {
      let receipt = try #require(try await pages.next())
      #expect(receipt.body == body)
      #expect(receipt.value == (try JSONDecoder().decode(BillSummaryPage.self, from: body)))
      #expect(receipt.status == 200)
    }
    #expect(try await pages.next() == nil)
    let expected = try bodies.flatMap {
      try JSONDecoder().decode(BillSummaryPage.self, from: $0).items
    }
    var actual: [BillSummary] = []
    for try await item in client(mock).items(for: try billRequest()) { actual.append(item) }
    #expect(actual == expected)
    #expect(mock.requests.map(\.request.path) == paths + paths)
  }

  @Test("Recorded empty historical and terminal scoped feeds finish successfully")
  func recordedEmptyHistoricalAndTerminalScopedFeedsFinishSuccessfully() async throws {
    let mock = MockTransport(results: [
      .success(Response(body: try Fixture.bill82_summaries_sparse.data(), status: .ok)),
      .success(Response(body: try Fixture.summary_updates119_hr_window.data(), status: .ok)),
    ])
    let historical = try BillSourceIdentifier(congress: 82, number: "677", type: .senateBill)
    var summaries = client(mock).summaries(for: historical, page: try CongressQuery(limit: 2))
      .makeAsyncIterator()
    #expect(try await summaries.next() == nil)
    let query = try Self.feedQuery(scope: .billType(congress: 119, type: .houseBill))
    var updates = client(mock).summaryUpdates(matching: query).makeAsyncIterator()
    #expect(try await updates.next()?.bill.number == "5437")
    #expect(try await updates.next() == nil)
    #expect(mock.requests.count == 2)
  }

  @Test("Recorded sorted feed corruption fails before its second page is yielded")
  func recordedSortedFeedCorruptionFailsBeforeItsSecondPageIsYielded() async throws {
    let first = try Fixture.summary_updates_window.data()
    let next = try Fixture.summary_updates_window_next.data()
    let mock = MockTransport(results: [
      .success(Response(body: first, status: .ok)), .success(Response(body: next, status: .ok)),
    ])
    var pages = client(mock).summaryUpdatePages(matching: try Self.feedQuery()).makeAsyncIterator()
    #expect(try await pages.next()?.body == first)
    let failure = await #expect(throws: CongressDataError.self) { _ = try await pages.next() }
    if case .invalidContinuation? = failure {
    } else {
      Issue.record("Expected invalid continuation")
    }
    #expect(try await pages.next() == nil)
    let recorded = try JSONDecoder().decode(BillSummaryUpdatePage.self, from: first)
    #expect(
      mock.requests.last?.request.path
        == recorded.pagination.next?.replacingOccurrences(of: "https://api.congress.gov", with: ""))
    #expect(mock.requests.count == 2)
  }

  @Test("Recorded unsorted feed traverses every page and item without prefetch")
  func recordedUnsortedFeedTraversesEveryPageAndItemWithoutPrefetch() async throws {
    let fixtures: [Fixture] = [
      .summary_updates_window_unsorted_first, .summary_updates_window_unsorted_next,
      .summary_updates_window_unsorted_third, .summary_updates_window_unsorted_terminal,
    ]
    let bodies = try fixtures.map { try $0.data() }
    let decoded = try bodies.map { try JSONDecoder().decode(BillSummaryUpdatePage.self, from: $0) }
    let paths = [
      "/v3/summaries?format=json&fromDateTime=2026-09-01T00:00:00Z&limit=2&offset=0&toDateTime=2026-09-02T00:00:00Z",
      "/v3/summaries?fromDateTime=2026-09-01T00:00:00Z&toDateTime=2026-09-02T00:00:00Z&offset=2&limit=2&format=json",
      "/v3/summaries?fromDateTime=2026-09-01T00:00:00Z&toDateTime=2026-09-02T00:00:00Z&offset=4&limit=2&format=json",
      "/v3/summaries?fromDateTime=2026-09-01T00:00:00Z&toDateTime=2026-09-02T00:00:00Z&offset=6&limit=2&format=json",
    ]
    #expect(decoded.map(\.summaries.count) == [2, 2, 2, 1])
    #expect(decoded.map(\.pagination.count) == [7, 7, 7, 7])
    #expect(decoded.last?.pagination.next == nil)
    let recorded = Dictionary(uniqueKeysWithValues: zip(paths, bodies))
    let mock = MockTransport()
    // Original bodies answer only their exact captured request targets.
    mock.setHandler(forPath: "/v3/summaries") { request in
      guard let path = request.path, let body = recorded[path] else {
        return .success(MockTransport.Answer(Response(status: .notFound)))
      }
      return .success(MockTransport.Answer(Response(body: body, status: .ok)))
    }
    let query = try SummaryQuery(
      fromDateTime: "2026-09-01T00:00:00Z", limit: 2, toDateTime: "2026-09-02T00:00:00Z")
    var pages = client(mock).summaryUpdatePages(matching: query).makeAsyncIterator()
    #expect(mock.requests.isEmpty)
    for index in bodies.indices {
      let receipt = try #require(try await pages.next())
      #expect(receipt.body == bodies[index])
      #expect(receipt.value == decoded[index])
      #expect(receipt.status == 200)
      #expect(mock.requests.map(\.request.path) == Array(paths.prefix(index + 1)))
    }
    #expect(try await pages.next() == nil)
    #expect(try await pages.next() == nil)
    #expect(mock.requests.map(\.request.path) == paths)

    let expected = decoded.flatMap(\.summaries)
    #expect(expected.map(\.bill.number) == ["4414", "1380", "1032", "547", "5437", "3516", "444"])
    var items = client(mock).summaryUpdates(matching: query).makeAsyncIterator()
    #expect(mock.requests.count == 4)
    var actual: [BillSummaryUpdate] = []
    for index in expected.indices {
      actual.append(try #require(try await items.next()))
      #expect(mock.requests.count == 4 + index / 2 + 1)
    }
    #expect(actual == expected)
    #expect(try await items.next() == nil)
    #expect(try await items.next() == nil)
    #expect(mock.requests.map(\.request.path) == paths + paths)
  }

  private func billRequest() throws -> CongressRequest<BillSummaryPage> {
    try .summaryConsumerExample
  }

  private func buffering<Page: CongressCollection & Equatable>(
    _ request: CongressRequest<Page>, fixture: Fixture
  ) async throws where Page.Item: Equatable {
    let bytes = try fixture.data()
    let decoded = try JSONDecoder().decode(Page.self, from: bytes)
    let mock = MockTransport(
      results: Array(repeating: .success(Response(body: bytes, status: .ok)), count: 6))
    let client = client(mock)
    let items = client.items(for: request)
    let pages = client.pages(for: request)
    var a = items.makeAsyncIterator()
    var b = items.makeAsyncIterator()
    #expect(mock.requests.isEmpty)
    #expect(try await a.next() == decoded.items[0])
    #expect(mock.requests.count == 1)
    #expect(try await a.next() == decoded.items[1])
    #expect(mock.requests.count == 1)
    #expect(try await b.next() == decoded.items[0])
    #expect(mock.requests.count == 2)
    for try await _ in items { break }
    #expect(mock.requests.count == 3)
    var count = 0
    for try await _ in items { count += 1; if count == decoded.items.count { break } }
    #expect(mock.requests.count == 4)
    for try await receipt in pages {
      #expect(receipt.body == bytes)
      #expect(receipt.value == decoded)
      break
    }
    #expect(mock.requests.count == 5)
    for call in mock.requests {
      #expect(call.request.scheme == "https")
      #expect(call.request.authority == "api.congress.gov")
      let key = try #require(HTTPField.Name("X-Api-Key"))
      #expect(call.request.headerFields[key] == "test-key")
    }
  }

  private func cancellation<Page: CongressCollection>(
    _ request: CongressRequest<Page>, fixture: Fixture
  ) async throws {
    for buffered in [false, true] {
      let mock = MockTransport(results: [.success(Response(body: try fixture.data(), status: .ok))])
      let items = client(mock).items(for: request)
      let ready = Gate()
      let resume = Gate()
      let task = Task {
        var iterator = items.makeAsyncIterator()
        if buffered { _ = try await iterator.next() }
        await ready.open()
        await resume.wait()
        let failure = await #expect(throws: CongressDataError.self) {
          _ = try await iterator.next()
        }
        if case .transport(.cancelled)? = failure {} else { Issue.record("Expected cancellation") }
        #expect(try await iterator.next() == nil)
      }
      await ready.wait()
      task.cancel()
      await resume.open()
      try await task.value
      #expect(mock.requests.count == (buffered ? 1 : 0))
    }
  }

  private func client(_ mock: MockTransport) -> CongressDataClient {
    CongressDataClient(
      configuration: .init(apiKey: "test-key", userAgent: "CongressTests"), transport: mock)
  }

  static func feedQuery(scope: SummaryQuery.Scope = .all) throws -> SummaryQuery {
    try SummaryQuery(
      fromDateTime: "2026-09-01T00:00:00Z", limit: 2, scope: scope,
      sort: .updateDateAscending, toDateTime: "2026-09-02T00:00:00Z")
  }

  private func invalidContinuation<Page: CongressCollection>(
    _ request: CongressRequest<Page>, fixture: Fixture, mutation: String
  ) async throws {
    // Labeled mutation of the recorded first page, never an official shape/route fixture.
    var object = try JSONDecoder().decode([String: JSONValue].self, from: fixture.data())
    var pagination = try #require(object["pagination"]?.object)
    var link = try #require(pagination["next"]?.string)
    switch mutation {
    case "origin": link = link.replacingOccurrences(of: "api.congress.gov", with: "example.com")
    case "path": link = link.replacingOccurrences(of: "/v3/", with: "/v3/bill/")
    case "identity": link = link.replacingOccurrences(of: "/summaries", with: "/summaries/118")
    case "credentials": link += "&api_key=secret"
    case "duplicate": link += "&offset=2"
    case "repeated": link = link.replacingOccurrences(of: "offset=2", with: "offset=0")
    case "skipped": link = link.replacingOccurrences(of: "offset=2", with: "offset=3")
    case "malformed": link = "not a URL"
    case "missing": pagination.removeValue(forKey: "next")
    case "limit": link = link.replacingOccurrences(of: "limit=2", with: "limit=3")
    case "filter": link += "&changed=true"
    case "overrun":
      var rows = try #require(object["summaries"]?.array)
      rows.append(rows[0])
      object["summaries"] = .array(rows)
    default: Issue.record("Unknown mutation")
    }
    if mutation != "missing" { pagination["next"] = .string(link) }
    object["pagination"] = .object(pagination)
    let mock = MockTransport(results: [
      .success(Response(body: try JSONEncoder().encode(object), status: .ok))
    ])
    var items = client(mock).items(for: request).makeAsyncIterator()
    let failure = await #expect(throws: CongressDataError.self) { _ = try await items.next() }
    if case .invalidContinuation? = failure {
    } else {
      Issue.record("Expected invalid continuation")
    }
    #expect(try await items.next() == nil)
    #expect(mock.requests.count == 1)
  }

  private func laterFailure<Page: CongressCollection>(
    _ request: CongressRequest<Page>, fixture: Fixture
  ) async throws {
    let mock = MockTransport(results: [
      .success(Response(body: try fixture.data(), status: .ok)),
      .success(Response(headers: [.retryAfter: "60"], status: .tooManyRequests)),
    ])
    var pages = client(mock).pages(for: request).makeAsyncIterator()
    _ = try await pages.next()
    let failure = await #expect(throws: CongressDataError.self) { _ = try await pages.next() }
    if case .transport(.httpStatus(_, let code, let headers))? = failure {
      #expect(code == 429)
      #expect(headers[.retryAfter] == "60")
    } else {
      Issue.record("Expected quota failure")
    }
    #expect(try await pages.next() == nil)
    #expect(mock.requests.count == 2)
  }
}
