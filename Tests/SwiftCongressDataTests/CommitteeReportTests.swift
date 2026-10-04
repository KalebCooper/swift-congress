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
struct CommitteeReportTests {
  @Test("All Committee report execution levels retrieve one response")
  func allCommitteeReportExecutionLevelsRetrieveOneResponse() async throws {
    let bytes = try Fixture.committee_house_hspw00_reports_chain_first.data()
    let mock = MockTransport(
      results: Array(repeating: .success(Response(body: bytes, status: .ok)), count: 7))
    let client = client(mock)
    let identifier = try CommitteeIdentifier(chamber: .house, code: "hspw00")
    let query = try CommitteeReportQuery(
      fromDateTime: "2015-03-20T00:04:12Z", limit: 12, toDateTime: "2015-03-20T00:06:53Z")
    let stored = CongressRequest.committeeReports(for: identifier, matching: query)
    let expected = try await client.value(for: stored)
    #expect(mock.requests.count == 1)
    let archive = CongressRequest.committeeReportsForArchive(for: identifier, matching: query)
    #expect(try await client.value(for: archive) == expected)
    #expect(mock.requests.count == 2)
    #expect(
      mock.requests.last?.request.path
        == Endpoint.committeeReports(for: identifier, matching: query).path)
    #expect(try await client.send(.committeeReports(for: identifier, matching: query)) == expected)
    var pages = client.committeeReportPages(for: identifier, matching: query).makeAsyncIterator()
    #expect(try await pages.next()?.value == expected)
    var items = client.committeeReports(for: identifier, matching: query).makeAsyncIterator()
    #expect(try await items.next() == expected.items.first)
    var custom = client.pages(
      for: CongressRequest(endpoint: .committeeReports(for: identifier, matching: query))
    )
    .makeAsyncIterator()
    #expect(try await custom.next()?.value == expected)
    #expect(try await custom.next() == nil)
    struct Consumer: Decodable, Sendable { let pagination: Pagination }
    let endpoint = try #require(
      Endpoint<Consumer>(path: Endpoint.committeeReports(for: identifier, matching: query).path))
    #expect(try await client.send(endpoint).pagination.count == 24)
    #expect(mock.requests.count == 7)
  }

  @Test("Committee report items cancel before HTTP and while buffered")
  func committeeReportItemsCancelBeforeHTTPAndWhileBuffered() async throws {
    let identifier = try CommitteeIdentifier(chamber: .house, code: "hspw00")
    let query = try CommitteeReportQuery(
      fromDateTime: "2015-03-20T00:04:12Z", limit: 12, toDateTime: "2015-03-20T00:06:53Z")
    for buffered in [false, true] {
      let mock = MockTransport(results: [
        .success(
          Response(
            body: try Fixture.committee_house_hspw00_reports_chain_first.data(), status: .ok
          ))
      ])
      let items = client(mock).committeeReports(for: identifier, matching: query)
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

  @Test("Committee report items fetch lazily and keep traversals independent")
  func committeeReportItemsFetchLazilyAndKeepTraversalsIndependent() async throws {
    let bytes = try Fixture.committee_house_hspw00_reports_chain_first.data()
    let mock = MockTransport(
      results: Array(repeating: .success(Response(body: bytes, status: .ok)), count: 3))
    let identifier = try CommitteeIdentifier(chamber: .house, code: "hspw00")
    let query = try CommitteeReportQuery(
      fromDateTime: "2015-03-20T00:04:12Z", limit: 12, toDateTime: "2015-03-20T00:06:53Z")
    let items = client(mock).committeeReports(for: identifier, matching: query)
    var a = items.makeAsyncIterator()
    var b = items.makeAsyncIterator()
    #expect(mock.requests.isEmpty)
    #expect(try await a.next()?.number == 570)
    #expect(try await a.next()?.number == 121)
    #expect(mock.requests.count == 1)
    #expect(try await b.next()?.number == 570)
    #expect(mock.requests.count == 2)
    for try await _ in items { break }
    #expect(mock.requests.count == 3)
    let key = try #require(HTTPField.Name("X-Api-Key"))
    for call in mock.requests {
      #expect(call.request.authority == "api.congress.gov")
      #expect(call.request.headerFields[key] == "test-key")
    }
  }

  @Test("Committee report pages remain lazy independent and cancellation aware")
  func committeeReportPagesRemainLazyIndependentAndCancellationAware() async throws {
    let bytes = try Fixture.committee_house_hspw00_reports_chain_first.data()
    let mock = MockTransport(
      results: Array(repeating: .success(Response(body: bytes, status: .ok)), count: 2))
    let identifier = try CommitteeIdentifier(chamber: .house, code: "hspw00")
    let query = try CommitteeReportQuery(
      fromDateTime: "2015-03-20T00:04:12Z", limit: 12, toDateTime: "2015-03-20T00:06:53Z")
    let pages = client(mock).committeeReportPages(for: identifier, matching: query)
    var a = pages.makeAsyncIterator()
    var b = pages.makeAsyncIterator()
    #expect(mock.requests.isEmpty)
    let first = try await a.next()
    #expect(mock.requests.count == 1)
    #expect(try await b.next()?.value == first?.value)
    #expect(mock.requests.count == 2)
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
    #expect(mock.requests.count == 2)
  }

  @Test(
    "Committee report traversal rejects changed scope filters and paging",
    arguments: ["count", "filter", "limit", "missing-next", "offset", "origin", "scope"])
  func committeeReportTraversalRejectsChangedScopeFiltersAndPaging(mutation: String) async throws {
    // Deliberate rejection mutations of recorded metadata.
    var fields = try JSONDecoder().decode(
      [String: JSONValue].self,
      from: Fixture.committee_house_hspw00_reports_chain_first.data())
    var pagination = try #require(fields["pagination"]?.object)
    var next = try #require(pagination["next"]?.string)
    switch mutation {
    case "count": pagination["count"] = .number(1)
    case "filter": next = next.replacingOccurrences(of: "00:04:12Z", with: "00:04:13Z")
    case "limit": next = next.replacingOccurrences(of: "limit=12", with: "limit=13")
    case "missing-next": break
    case "offset": next = next.replacingOccurrences(of: "offset=12", with: "offset=0")
    case "origin": next = next.replacingOccurrences(of: "api.congress.gov", with: "example.com")
    case "scope": next = next.replacingOccurrences(of: "/house/hspw00", with: "/senate/ssju00")
    default: Issue.record("Unknown mutation")
    }
    pagination["next"] = mutation == "missing-next" ? nil : .string(next)
    fields["pagination"] = .object(pagination)
    let mock = MockTransport(results: [
      .success(Response(body: try JSONEncoder().encode(fields), status: .ok))
    ])
    let identifier = try CommitteeIdentifier(chamber: .house, code: "hspw00")
    let query = try CommitteeReportQuery(
      fromDateTime: "2015-03-20T00:04:12Z", limit: 12, toDateTime: "2015-03-20T00:06:53Z")
    var items = client(mock).committeeReports(for: identifier, matching: query).makeAsyncIterator()
    let failure = await #expect(throws: CongressDataError.self) { _ = try await items.next() }
    if case .invalidContinuation? = failure {
    } else {
      Issue.record("Expected invalid continuation")
    }
    #expect(try await items.next() == nil)
    #expect(mock.requests.count == 1)
  }

  @Test("Committee report traversals retain later quota failures")
  func committeeReportTraversalsRetainLaterQuotaFailures() async throws {
    let mock = MockTransport(results: [
      .success(
        Response(
          body: try Fixture.committee_house_hspw00_reports_chain_first.data(), status: .ok)),
      .success(Response(headers: [.retryAfter: "60"], status: .tooManyRequests)),
    ])
    let identifier = try CommitteeIdentifier(chamber: .house, code: "hspw00")
    let query = try CommitteeReportQuery(
      fromDateTime: "2015-03-20T00:04:12Z", limit: 12, toDateTime: "2015-03-20T00:06:53Z")
    var pages = client(mock).committeeReportPages(for: identifier, matching: query)
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

  @Test("Recorded committee report chains follow exact links and terminate")
  func recordedCommitteeReportChainsFollowExactLinksAndTerminate() async throws {
    let bodies = try [
      Fixture.committee_house_hspw00_reports_chain_first,
      .committee_house_hspw00_reports_chain_terminal,
    ].map {
      try $0.data()
    }
    let paths = [
      "/v3/committee/house/hspw00/reports?format=json&fromDateTime=2015-03-20T00:04:12Z&limit=12&offset=0&toDateTime=2015-03-20T00:06:53Z",
      "/v3/committee/house/hspw00/reports?fromDateTime=2015-03-20T00:04:12Z&toDateTime=2015-03-20T00:06:53Z&offset=12&limit=12&format=json",
    ]
    let recorded = Dictionary(uniqueKeysWithValues: zip(paths, bodies))
    let mock = MockTransport()
    mock.setHandler(forPath: "/v3/committee/house/hspw00/reports") { request in
      guard let path = request.path, let body = recorded[path] else {
        return .success(MockTransport.Answer(Response(status: .notFound)))
      }
      return .success(MockTransport.Answer(Response(body: body, status: .ok)))
    }
    let identifier = try CommitteeIdentifier(chamber: .house, code: "hspw00")
    let query = try CommitteeReportQuery(
      fromDateTime: "2015-03-20T00:04:12Z", limit: 12, toDateTime: "2015-03-20T00:06:53Z")
    var pages = client(mock).committeeReportPages(for: identifier, matching: query)
      .makeAsyncIterator()
    for index in bodies.indices {
      let receipt = try #require(try await pages.next())
      #expect(receipt.body == bodies[index])
      #expect(receipt.value.pagination.count == 24)
      #expect(mock.requests.map(\.request.path) == Array(paths.prefix(index + 1)))
    }
    #expect(try await pages.next() == nil)
    var actual: [CommitteeReportReference] = []
    for try await report in client(mock).committeeReports(for: identifier, matching: query) {
      actual.append(report)
    }
    let expected = try bodies.flatMap {
      try JSONDecoder().decode(CommitteeReportPage.self, from: $0).items
    }
    #expect(actual == expected)
    #expect(actual.count == 24)
    #expect(mock.requests.map(\.request.path) == paths + paths)
  }

  private func client(_ mock: MockTransport) -> CongressDataClient {
    CongressDataClient(
      configuration: .init(apiKey: "test-key", userAgent: "CongressTests"), transport: mock)
  }
}

private extension CongressRequest where Response == CommitteeReportPage {
  static func committeeReportsForArchive(
    for identifier: CommitteeIdentifier, matching query: CommitteeReportQuery
  ) -> Self {
    .committeeReports(for: identifier, matching: query)
  }
}
