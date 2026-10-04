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

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct CommitteeReportTextTests {
  @Test("All Committee report text execution levels retrieve one response")
  func allCommitteeReportTextExecutionLevelsRetrieveOneResponse() async throws {
    let bytes = try Fixture.committee_report_109_hrpt_519_text_first.data()
    let mock = MockTransport(
      results: Array(repeating: .success(Response(body: bytes, status: .ok)), count: 10))
    let client = client(mock)
    let identifier = try CommitteeReportIdentifier(congress: 109, number: "519", type: .houseReport)
    let query = try CongressQuery(limit: 1)
    let stored = CongressRequest.textVersions(for: identifier, page: query)
    let expected = try await client.value(for: stored)
    #expect(mock.requests.count == 1)
    let archive = CongressRequest.reportTextForArchive(
      for: identifier, page: query)
    #expect(try await client.value(for: archive) == expected)
    #expect(mock.requests.count == 2)
    #expect(
      mock.requests.last?.request.path
        == (Endpoint.textVersions(for: identifier, page: query).path))
    #expect(
      try await client.value(for: .textVersions(for: identifier, page: query))
        == expected)
    #expect(
      try await client.send(.textVersions(for: identifier, page: query))
        == expected
    )
    var pages = client.committeeReportTextPages(for: identifier, page: query)
      .makeAsyncIterator()
    #expect(try await pages.next()?.value == expected)
    var items = client.committeeReportTextVersions(for: identifier, page: query)
      .makeAsyncIterator()
    #expect(try await items.next() == expected.items.first)
    var genericPages = client.pages(for: stored).makeAsyncIterator()
    #expect(try await genericPages.next()?.value == expected)
    var genericItems = client.items(for: stored).makeAsyncIterator()
    #expect(try await genericItems.next() == expected.items.first)
    var custom = client.pages(
      for: CongressRequest(endpoint: .textVersions(for: identifier, page: query))
    )
    .makeAsyncIterator()
    #expect(try await custom.next()?.value == expected)
    #expect(try await custom.next() == nil)
    struct Consumer: Decodable, Sendable { let pagination: Pagination }
    let endpoint = try #require(
      Endpoint<Consumer>(
        path: Endpoint.textVersions(for: identifier, page: query).path))
    #expect(try await client.response(for: endpoint).value.pagination.count == 4)
    #expect(mock.requests.count == 10)
  }

  @Test("Committee report text items cancel before HTTP and while buffered")
  func committeeReportTextItemsCancelBeforeHTTPAndWhileBuffered() async throws {
    let identifier = try CommitteeReportIdentifier(congress: 109, number: "519", type: .houseReport)
    let query = try CongressQuery(limit: 2)
    for buffered in [false, true] {
      let mock = MockTransport(results: [
        .success(
          Response(
            body: try bufferedTextBody(),
            status: .ok
          ))
      ])
      let items = client(mock).committeeReportTextVersions(for: identifier, page: query)
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

  @Test("Committee report text items fetch lazily and keep traversals independent")
  func committeeReportTextItemsFetchLazilyAndKeepTraversalsIndependent() async throws {
    let bytes = try bufferedTextBody()
    let mock = MockTransport(
      results: Array(repeating: .success(Response(body: bytes, status: .ok)), count: 4))
    let identifier = try CommitteeReportIdentifier(congress: 109, number: "519", type: .houseReport)
    let query = try CongressQuery(limit: 2)
    let items = client(mock).committeeReportTextVersions(for: identifier, page: query)
    var a = items.makeAsyncIterator()
    var b = items.makeAsyncIterator()
    #expect(mock.requests.isEmpty)
    #expect(try await a.next()?.formats?.first?.isErrata == "N")
    #expect(try await a.next()?.formats?.first?.isErrata == "N")
    #expect(mock.requests.count == 1)
    #expect(try await b.next()?.formats?.first?.isErrata == "N")
    #expect(mock.requests.count == 2)
    var bufferedCount = 0
    for try await _ in items {
      bufferedCount += 1
      if bufferedCount == 2 { break }
    }
    #expect(mock.requests.count == 3)
    for try await _ in items { break }
    #expect(mock.requests.count == 4)
    let key = try #require(HTTPField.Name("X-Api-Key"))
    for call in mock.requests {
      #expect(call.request.authority == "api.congress.gov")
      #expect(call.request.headerFields[key] == "test-key")
    }
  }

  @Test("Committee report text pages remain lazy independent and cancellation aware")
  func committeeReportTextPagesRemainLazyIndependentAndCancellationAware() async throws {
    let bytes = try Fixture.committee_report_109_hrpt_519_text_first.data()
    let mock = MockTransport(
      results: Array(repeating: .success(Response(body: bytes, status: .ok)), count: 3))
    let identifier = try CommitteeReportIdentifier(congress: 109, number: "519", type: .houseReport)
    let query = try CongressQuery(limit: 1)
    let pages = client(mock).committeeReportTextPages(for: identifier, page: query)
    var a = pages.makeAsyncIterator()
    var b = pages.makeAsyncIterator()
    #expect(mock.requests.isEmpty)
    let first = try await a.next()
    #expect(mock.requests.count == 1)
    #expect(try await b.next()?.value == first?.value)
    #expect(mock.requests.count == 2)
    for try await _ in pages { break }
    #expect(mock.requests.count == 3)
    let ready = Gate()
    let resume = Gate()
    let task = Task {
      var iterator = pages.makeAsyncIterator()
      await ready.open()
      await resume.wait()
      let failure = await #expect(throws: CongressDataError.self) { _ = try await iterator.next() }
      if case .transport(.cancelled)? = failure {} else { Issue.record("Expected cancellation") }
      let terminal = try await iterator.next()
      #expect(terminal == nil)
    }
    await ready.wait()
    task.cancel()
    await resume.open()
    try await task.value
    #expect(mock.requests.count == 3)
  }

  @Test(
    "Committee report text traversal rejects changed scope filters and paging",
    arguments: [
      "count", "credential", "duplicate", "filter", "limit", "malformed", "missing-next", "offset",
      "origin", "overrun", "scope",
    ])
  func committeeReportTextTraversalRejectsChangedScopeFiltersAndPaging(mutation: String)
    async throws
  {
    // Deliberate rejection mutations of recorded metadata.
    var fields = try JSONDecoder().decode(
      [String: JSONValue].self,
      from: Fixture.committee_report_109_hrpt_519_text_first.data())
    var pagination = try #require(fields["pagination"]?.object)
    var next = try #require(pagination["next"]?.string)
    switch mutation {
    case "count": pagination["count"] = .number(0)
    case "credential": next += "&api_key=secret"
    case "duplicate": next += "&offset=1"
    case "filter": next += "&fromDateTime=2020-01-01T00:00:00Z"
    case "limit": next = next.replacingOccurrences(of: "limit=1", with: "limit=2")
    case "malformed": next = "not a URL"
    case "missing-next": break
    case "offset": next = next.replacingOccurrences(of: "offset=1", with: "offset=0")
    case "origin": next = next.replacingOccurrences(of: "api.congress.gov", with: "example.com")
    case "overrun":
      let records = try #require(fields["text"]?.array)
      fields["text"] = .array(records + records)
    case "scope": next = next.replacingOccurrences(of: "/hrpt/519", with: "/hrpt/520")
    default: Issue.record("Unknown mutation")
    }
    pagination["next"] = mutation == "missing-next" ? nil : .string(next)
    fields["pagination"] = .object(pagination)
    let mock = MockTransport(results: [
      .success(Response(body: try JSONEncoder().encode(fields), status: .ok))
    ])
    let identifier = try CommitteeReportIdentifier(congress: 109, number: "519", type: .houseReport)
    let query = try CongressQuery(limit: 1)
    var items = client(mock).committeeReportTextVersions(for: identifier, page: query)
      .makeAsyncIterator()
    let failure = await #expect(throws: CongressDataError.self) { _ = try await items.next() }
    if case .invalidContinuation? = failure {
    } else {
      Issue.record("Expected invalid continuation")
    }
    #expect(try await items.next() == nil)
    #expect(mock.requests.count == 1)
  }

  @Test(
    "Committee report text traversals reject a repeated later next link before yielding")
  func committeeReportTextTraversalsRejectARepeatedLaterNextLinkBeforeYielding()
    async throws
  {
    let first = try Fixture.committee_report_109_hrpt_519_text_first.data()
    var fields = try JSONDecoder().decode(
      [String: JSONValue].self,
      from: Fixture.committee_report_109_hrpt_519_text_next.data())
    var pagination = try #require(fields["pagination"]?.object)
    let initial = try JSONDecoder().decode(CommitteeReportTextPage.self, from: first)
    pagination["next"] = initial.rawFields["pagination"]?.object?["next"]
    fields["pagination"] = .object(pagination)
    let mock = MockTransport(results: [
      .success(Response(body: first, status: .ok)),
      .success(Response(body: try JSONEncoder().encode(fields), status: .ok)),
    ])
    let identifier = try CommitteeReportIdentifier(congress: 109, number: "519", type: .houseReport)
    let query = try CongressQuery(limit: 1)
    var pages = client(mock).committeeReportTextPages(for: identifier, page: query)
      .makeAsyncIterator()
    #expect(try await pages.next()?.body == first)
    let failure = await #expect(throws: CongressDataError.self) { _ = try await pages.next() }
    if case .invalidContinuation? = failure {
    } else {
      Issue.record("Expected invalid continuation")
    }
    #expect(try await pages.next() == nil)
    #expect(mock.requests.count == 2)
  }

  @Test("Committee report text traversals retain later quota failures")
  func committeeReportTextTraversalsRetainLaterQuotaFailures() async throws {
    let mock = MockTransport(results: [
      .success(
        Response(
          body: try Fixture.committee_report_109_hrpt_519_text_first.data(),
          status: .ok)),
      .success(Response(headers: [.retryAfter: "60"], status: .tooManyRequests)),
    ])
    let identifier = try CommitteeReportIdentifier(congress: 109, number: "519", type: .houseReport)
    let query = try CongressQuery(limit: 1)
    var pages = client(mock).committeeReportTextPages(for: identifier, page: query)
      .makeAsyncIterator()
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

  @Test("Recorded committee report text chains follow exact links and terminate")
  func recordedCommitteeReportTextChainsFollowExactLinksAndTerminate() async throws {
    let bodies = try [
      Fixture.committee_report_109_hrpt_519_text_first,
      Fixture.committee_report_109_hrpt_519_text_next,
      Fixture.committee_report_109_hrpt_519_text_third,
      Fixture.committee_report_109_hrpt_519_text_terminal,
    ].map { try $0.data() }
    let paths = [
      "/v3/committee-report/109/hrpt/519/text?format=json&limit=1&offset=0",
      "/v3/committee-report/109/hrpt/519/text?offset=1&limit=1&format=json",
      "/v3/committee-report/109/hrpt/519/text?offset=2&limit=1&format=json",
      "/v3/committee-report/109/hrpt/519/text?offset=3&limit=1&format=json",
    ]
    let recorded = Dictionary(uniqueKeysWithValues: zip(paths, bodies))
    let mock = MockTransport()
    mock.setHandler(forPath: "/v3/committee-report/109/hrpt/519/text") { request in
      guard let path = request.path, let body = recorded[path] else {
        return .success(MockTransport.Answer(Response(status: .notFound)))
      }
      return .success(MockTransport.Answer(Response(body: body, status: .ok)))
    }
    let identifier = try CommitteeReportIdentifier(congress: 109, number: "519", type: .houseReport)
    let query = try CongressQuery(limit: 1)
    var pages = client(mock).committeeReportTextPages(for: identifier, page: query)
      .makeAsyncIterator()
    for index in bodies.indices {
      let receipt = try #require(try await pages.next())
      #expect(receipt.body == bodies[index])
      #expect(
        try receipt.value == JSONDecoder().decode(CommitteeReportTextPage.self, from: bodies[index])
      )
      #expect(receipt.value.pagination.count == 4)
      #expect(mock.requests.map(\.request.path) == Array(paths.prefix(index + 1)))
    }
    #expect(try await pages.next() == nil)
    var actual: [CommitteeReportTextVersion] = []
    for try await record in client(mock).committeeReportTextVersions(for: identifier, page: query) {
      actual.append(record)
    }
    let expected = try bodies.flatMap {
      try JSONDecoder().decode(CommitteeReportTextPage.self, from: $0).items
    }
    #expect(actual == expected)
    #expect(actual.count == 4)
    #expect(mock.requests.map(\.request.path) == paths + paths)
  }

  private func bufferedTextBody() throws -> Data {
    // Explicit duplicate mutation for buffering only, not additional production evidence.
    var fields = try JSONDecoder().decode(
      [String: JSONValue].self,
      from: Fixture.committee_report_109_hrpt_519_text_first.data())
    let records = try #require(fields["text"]?.array)
    fields["text"] = .array(records + records)
    var pagination = try #require(fields["pagination"]?.object)
    pagination["next"] = .string(
      "https://api.congress.gov/v3/committee-report/109/hrpt/519/text?offset=2&limit=2&format=json")
    fields["pagination"] = .object(pagination)
    return try JSONEncoder().encode(fields)
  }

  private func client(_ mock: MockTransport) -> CongressDataClient {
    CongressDataClient(
      configuration: .init(apiKey: "test-key", userAgent: "CongressTests"), transport: mock)
  }
}

private extension CongressRequest where Response == CommitteeReportTextPage {
  static func reportTextForArchive(
    for identifier: CommitteeReportIdentifier, page query: CongressQuery
  ) -> Self {
    .textVersions(for: identifier, page: query)
  }
}
