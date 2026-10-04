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
struct CommitteeReportInventoryTests {
  @Test("All Committee report inventory execution levels retrieve one response")
  func allCommitteeReportInventoryExecutionLevelsRetrieveOneResponse() async throws {
    let bytes = try Fixture.committee_report_117_srpt_chain_first.data()
    let mock = MockTransport(
      results: Array(repeating: .success(Response(body: bytes, status: .ok)), count: 10))
    let client = client(mock)

    let query = try CommitteeReportInventoryQuery(
      limit: 96, scope: .type(congress: 117, type: .senateReport))
    let stored = CongressRequest.committeeReports(matching: query)
    let expected = try await client.value(for: stored)
    #expect(mock.requests.count == 1)
    let archive = CongressRequest.reportInventoryForArchive(
      matching: query)
    #expect(try await client.value(for: archive) == expected)
    #expect(mock.requests.count == 2)
    #expect(
      mock.requests.last?.request.path
        == (Endpoint.committeeReports(matching: query).path))
    #expect(
      try await client.value(for: .committeeReports(matching: query))
        == expected)
    #expect(
      try await client.send(.committeeReports(matching: query))
        == expected
    )
    var pages = client.committeeReportPages(matching: query)
      .makeAsyncIterator()
    #expect(try await pages.next()?.value == expected)
    var items = client.committeeReports(matching: query)
      .makeAsyncIterator()
    #expect(try await items.next() == expected.items.first)
    var genericPages = client.pages(for: stored).makeAsyncIterator()
    #expect(try await genericPages.next()?.value == expected)
    var genericItems = client.items(for: stored).makeAsyncIterator()
    #expect(try await genericItems.next() == expected.items.first)
    var custom = client.pages(
      for: CongressRequest(endpoint: .committeeReports(matching: query))
    )
    .makeAsyncIterator()
    #expect(try await custom.next()?.value == expected)
    #expect(try await custom.next() == nil)
    struct Consumer: Decodable, Sendable { let pagination: Pagination }
    let endpoint = try #require(
      Endpoint<Consumer>(
        path: Endpoint.committeeReports(matching: query).path))
    #expect(try await client.response(for: endpoint).value.pagination.count == 286)
    #expect(mock.requests.count == 10)
  }

  @Test("All report detail execution levels preserve every part in one response")
  func allReportDetailExecutionLevelsPreserveEveryPartInOneResponse() async throws {
    let bytes = try Fixture.committee_report_109_hrpt_519_detail.data()
    let mock = MockTransport(
      results: Array(repeating: .success(Response(body: bytes, status: .ok)), count: 7))
    let client = client(mock)
    let identifier = try CommitteeReportIdentifier(congress: 109, number: "519", type: .houseReport)
    let stored = CongressRequest.committeeReport(identifier)
    #expect(mock.requests.isEmpty)
    let expected = try await client.committeeReport(identifier)
    #expect(expected.committeeReports.map(\.part) == [1, 2])
    #expect(mock.requests.count == 1)
    #expect(try await client.value(for: stored) == expected)
    #expect(try await client.value(for: .committeeReport(identifier)) == expected)
    #expect(try await client.value(for: .reportDetailForArchive(identifier)) == expected)
    #expect(try await client.send(.committeeReport(identifier)) == expected)
    #expect(
      try await client.value(for: CongressRequest(endpoint: .committeeReport(identifier)))
        == expected)
    struct Consumer: Decodable, Sendable { let committeeReports: [CommitteeReportPart] }
    let endpoint = try #require(Endpoint<Consumer>(path: Endpoint.committeeReport(identifier).path))
    let receipt = try await client.response(for: endpoint)
    #expect(receipt.body == bytes)
    #expect(receipt.value.committeeReports == expected.committeeReports)
    #expect(mock.requests.count == 7)
    #expect(
      mock.requests.allSatisfy { $0.request.path == Endpoint.committeeReport(identifier).path })
  }

  @Test("Committee report inventory items cancel before HTTP and while buffered")
  func committeeReportInventoryItemsCancelBeforeHTTPAndWhileBuffered() async throws {

    let query = try CommitteeReportInventoryQuery(
      limit: 96, scope: .type(congress: 117, type: .senateReport))
    for buffered in [false, true] {
      let mock = MockTransport(results: [
        .success(
          Response(
            body: try Fixture.committee_report_117_srpt_chain_first.data(),
            status: .ok
          ))
      ])
      let items = client(mock).committeeReports(matching: query)
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

  @Test("Committee report inventory items fetch lazily and keep traversals independent")
  func committeeReportInventoryItemsFetchLazilyAndKeepTraversalsIndependent() async throws {
    let bytes = try Fixture.committee_report_117_srpt_chain_first.data()
    let mock = MockTransport(
      results: Array(repeating: .success(Response(body: bytes, status: .ok)), count: 4))

    let query = try CommitteeReportInventoryQuery(
      limit: 96, scope: .type(congress: 117, type: .senateReport))
    let items = client(mock).committeeReports(matching: query)
    var a = items.makeAsyncIterator()
    var b = items.makeAsyncIterator()
    #expect(mock.requests.isEmpty)
    #expect(try await a.next()?.number == 1)
    #expect(try await a.next()?.number == 3)
    #expect(mock.requests.count == 1)
    for _ in 2..<96 { _ = try await a.next() }
    #expect(mock.requests.count == 1)
    #expect(try await b.next()?.number == 1)
    #expect(mock.requests.count == 2)
    var bufferedCount = 0
    for try await _ in items {
      bufferedCount += 1
      if bufferedCount == 96 { break }
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

  @Test("Committee report inventory pages remain lazy independent and cancellation aware")
  func committeeReportInventoryPagesRemainLazyIndependentAndCancellationAware() async throws {
    let bytes = try Fixture.committee_report_117_srpt_chain_first.data()
    let mock = MockTransport(
      results: Array(repeating: .success(Response(body: bytes, status: .ok)), count: 3))

    let query = try CommitteeReportInventoryQuery(
      limit: 96, scope: .type(congress: 117, type: .senateReport))
    let pages = client(mock).committeeReportPages(matching: query)
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
    "Committee report inventory traversal rejects changed scope filters and paging",
    arguments: [
      "count", "credential", "duplicate", "filter", "limit", "malformed", "missing-next", "offset",
      "origin", "scope",
    ])
  func committeeReportInventoryTraversalRejectsChangedScopeFiltersAndPaging(mutation: String)
    async throws
  {
    // Deliberate rejection mutations of recorded metadata.
    var fields = try JSONDecoder().decode(
      [String: JSONValue].self,
      from: Fixture.committee_report_117_srpt_chain_first.data())
    var pagination = try #require(fields["pagination"]?.object)
    var next = try #require(pagination["next"]?.string)
    switch mutation {
    case "count": pagination["count"] = .number(1)
    case "credential": next += "&api_key=secret"
    case "duplicate": next += "&offset=96"
    case "filter": next += "&conference=true"
    case "limit": next = next.replacingOccurrences(of: "limit=96", with: "limit=97")
    case "malformed": next = "not a URL"
    case "missing-next": break
    case "offset": next = next.replacingOccurrences(of: "offset=96", with: "offset=0")
    case "origin": next = next.replacingOccurrences(of: "api.congress.gov", with: "example.com")
    case "scope": next = next.replacingOccurrences(of: "/117/srpt", with: "/118/srpt")
    default: Issue.record("Unknown mutation")
    }
    pagination["next"] = mutation == "missing-next" ? nil : .string(next)
    fields["pagination"] = .object(pagination)
    let mock = MockTransport(results: [
      .success(Response(body: try JSONEncoder().encode(fields), status: .ok))
    ])

    let query = try CommitteeReportInventoryQuery(
      limit: 96, scope: .type(congress: 117, type: .senateReport))
    var items = client(mock).committeeReports(matching: query)
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
    "Committee report inventory traversals reject a repeated later next link before yielding")
  func committeeReportInventoryTraversalsRejectARepeatedLaterNextLinkBeforeYielding()
    async throws
  {
    let first = try Fixture.committee_report_117_srpt_chain_first.data()
    var fields = try JSONDecoder().decode(
      [String: JSONValue].self,
      from: Fixture.committee_report_117_srpt_chain_next.data())
    var pagination = try #require(fields["pagination"]?.object)
    let initial = try JSONDecoder().decode(CommitteeReportPage.self, from: first)
    pagination["next"] = initial.rawFields["pagination"]?.object?["next"]
    fields["pagination"] = .object(pagination)
    let mock = MockTransport(results: [
      .success(Response(body: first, status: .ok)),
      .success(Response(body: try JSONEncoder().encode(fields), status: .ok)),
    ])

    let query = try CommitteeReportInventoryQuery(
      limit: 96, scope: .type(congress: 117, type: .senateReport))
    var pages = client(mock).committeeReportPages(matching: query)
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

  @Test("Committee report inventory traversals retain later quota failures")
  func committeeReportInventoryTraversalsRetainLaterQuotaFailures() async throws {
    let mock = MockTransport(results: [
      .success(
        Response(
          body: try Fixture.committee_report_117_srpt_chain_first.data(),
          status: .ok)),
      .success(Response(headers: [.retryAfter: "60"], status: .tooManyRequests)),
    ])

    let query = try CommitteeReportInventoryQuery(
      limit: 96, scope: .type(congress: 117, type: .senateReport))
    var pages = client(mock).committeeReportPages(matching: query)
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

  @Test("Recorded committee report inventory chains follow exact links and terminate")
  func recordedCommitteeReportInventoryChainsFollowExactLinksAndTerminate() async throws {
    let bodies = try [
      Fixture.committee_report_117_srpt_chain_first, Fixture.committee_report_117_srpt_chain_next,
      Fixture.committee_report_117_srpt_chain_terminal,
    ].map { try $0.data() }
    let paths = [
      "/v3/committee-report/117/srpt?format=json&limit=96&offset=0",
      "/v3/committee-report/117/srpt?offset=96&limit=96&format=json",
      "/v3/committee-report/117/srpt?offset=192&limit=96&format=json",
    ]
    let recorded = Dictionary(uniqueKeysWithValues: zip(paths, bodies))
    let mock = MockTransport()
    mock.setHandler(forPath: "/v3/committee-report/117/srpt") { request in
      guard let path = request.path, let body = recorded[path] else {
        return .success(MockTransport.Answer(Response(status: .notFound)))
      }
      return .success(MockTransport.Answer(Response(body: body, status: .ok)))
    }
    let query = try CommitteeReportInventoryQuery(
      limit: 96, scope: .type(congress: 117, type: .senateReport))
    var pages = client(mock).committeeReportPages(matching: query).makeAsyncIterator()
    for index in bodies.indices {
      let receipt = try #require(try await pages.next())
      #expect(receipt.body == bodies[index])
      #expect(
        try receipt.value == JSONDecoder().decode(CommitteeReportPage.self, from: bodies[index]))
      #expect(receipt.value.pagination.count == 286)
      #expect(mock.requests.map(\.request.path) == Array(paths.prefix(index + 1)))
    }
    #expect(try await pages.next() == nil)
    var actual: [CommitteeReportReference] = []
    for try await record in client(mock).committeeReports(matching: query) { actual.append(record) }
    let expected = try bodies.flatMap {
      try JSONDecoder().decode(CommitteeReportPage.self, from: $0).items
    }
    #expect(actual == expected)
    #expect(actual.count == 286)
    #expect(mock.requests.map(\.request.path) == paths + paths)
  }

  private func client(_ mock: MockTransport) -> CongressDataClient {
    CongressDataClient(
      configuration: .init(apiKey: "test-key", userAgent: "CongressTests"), transport: mock)
  }
}

private extension CongressRequest where Response == CommitteeReportDetail {
  static func reportDetailForArchive(_ identifier: CommitteeReportIdentifier) -> Self {
    .committeeReport(identifier)
  }
}

private extension CongressRequest where Response == CommitteeReportPage {
  static func reportInventoryForArchive(
    matching query: CommitteeReportInventoryQuery
  ) -> Self {
    .committeeReports(matching: query)
  }
}
