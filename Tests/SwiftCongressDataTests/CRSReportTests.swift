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
struct CRSReportTests {
  @Test("All CRS execution levels retrieve one response")
  func allCRSExecutionLevelsRetrieveOneResponse() async throws {
    let bytes = try Fixture.crs_reports_day_first.data()
    let mock = MockTransport(
      results: Array(repeating: .success(Response(body: bytes, status: .ok)), count: 6))
    let client = client(mock)
    let query = try CRSReportQuery(
      fromDateTime: "2026-10-03T00:00:00Z", limit: 5, toDateTime: "2026-10-04T00:00:00Z")
    let stored = CongressRequest.crsReports(matching: query)
    let expected = try await client.value(for: stored)
    #expect(try await client.send(.crsReports(matching: query)) == expected)
    var pages = client.crsReportPages(matching: query).makeAsyncIterator()
    #expect(try await pages.next()?.value == expected)
    var items = client.crsReports(matching: query).makeAsyncIterator()
    #expect(try await items.next() == expected.items.first)
    var custom = client.pages(for: CongressRequest(endpoint: .crsReports(matching: query)))
      .makeAsyncIterator()
    #expect(try await custom.next()?.value == expected)
    #expect(try await custom.next() == nil)
    struct Consumer: Decodable, Sendable { let pagination: Pagination }
    let endpoint = try #require(Endpoint<Consumer>(path: Endpoint.crsReports(matching: query).path))
    #expect(try await client.send(endpoint).pagination.count == 9)
    #expect(mock.requests.count == 6)
  }

  @Test("CRS detail conveniences preserve receipts without fetching linked assets")
  func crsDetailConveniencesPreserveReceiptsWithoutFetchingLinkedAssets() async throws {
    let bytes = try Fixture.crs_report_r47175.data()
    let mock = MockTransport(
      results: Array(repeating: .success(Response(body: bytes, status: .ok)), count: 3))
    let client = client(mock)
    let identifier = try CRSReportIdentifier(rawValue: "R47175")
    let expected = try await client.crsReport(identifier)
    #expect(try await client.value(for: .crsReport(identifier)) == expected)
    #expect(try await client.send(.crsReport(identifier)) == expected)
    #expect(
      mock.requests.map(\.request.path)
        == Array(repeating: "/v3/crsreport/R47175?format=json", count: 3))
  }

  @Test("CRS items cancel before HTTP and while buffered")
  func crsItemsCancelBeforeHTTPAndWhileBuffered() async throws {
    let query = try CRSReportQuery(
      fromDateTime: "2026-10-03T00:00:00Z", limit: 5, toDateTime: "2026-10-04T00:00:00Z")
    for buffered in [false, true] {
      let mock = MockTransport(results: [
        .success(Response(body: try Fixture.crs_reports_day_first.data(), status: .ok))
      ])
      let items = client(mock).crsReports(matching: query)
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

  @Test("CRS items fetch lazily and keep traversals independent")
  func crsItemsFetchLazilyAndKeepTraversalsIndependent() async throws {
    let bytes = try Fixture.crs_reports_day_first.data()
    let mock = MockTransport(
      results: Array(repeating: .success(Response(body: bytes, status: .ok)), count: 3))
    let query = try CRSReportQuery(
      fromDateTime: "2026-10-03T00:00:00Z", limit: 5, toDateTime: "2026-10-04T00:00:00Z")
    let items = client(mock).crsReports(matching: query)
    var a = items.makeAsyncIterator()
    var b = items.makeAsyncIterator()
    #expect(mock.requests.isEmpty)
    #expect(try await a.next()?.id == "IF10199")
    #expect(try await a.next()?.id == "R49457")
    #expect(mock.requests.count == 1)
    #expect(try await b.next()?.id == "IF10199")
    #expect(mock.requests.count == 2)
    for try await _ in items { break }
    #expect(mock.requests.count == 3)
    let key = try #require(HTTPField.Name("X-Api-Key"))
    for call in mock.requests {
      #expect(call.request.authority == "api.congress.gov")
      #expect(call.request.headerFields[key] == "test-key")
    }
  }

  @Test(
    "CRS traversal rejects changed filters links counts and page sizes",
    arguments: [
      "count", "credentials", "duplicate", "filter", "limit", "missing", "origin", "overrun",
      "path", "repeated", "skipped",
    ])
  func crsTraversalRejectsChangedFiltersLinksCountsAndPageSizes(mutation: String) async throws {
    // Mutations of a recorded response are rejection tests, not source evidence.
    var fields = try JSONDecoder().decode(
      [String: JSONValue].self, from: Fixture.crs_reports_day_first.data())
    var pagination = try #require(fields["pagination"]?.object)
    var link = try #require(pagination["next"]?.string)
    switch mutation {
    case "count": pagination["count"] = .number(4)
    case "credentials": link += "&api_key=secret"
    case "duplicate": link += "&offset=5"
    case "filter": link = link.replacingOccurrences(of: "2026-10-03", with: "2026-10-02")
    case "limit": link = link.replacingOccurrences(of: "limit=5", with: "limit=6")
    case "missing": pagination.removeValue(forKey: "next")
    case "origin": link = link.replacingOccurrences(of: "api.congress.gov", with: "example.com")
    case "overrun":
      var rows = try #require(fields["CRSReports"]?.array)
      rows.append(rows[0])
      fields["CRSReports"] = .array(rows)
    case "path": link = link.replacingOccurrences(of: "/crsreport?", with: "/member?")
    case "repeated": link = link.replacingOccurrences(of: "offset=5", with: "offset=0")
    case "skipped": link = link.replacingOccurrences(of: "offset=5", with: "offset=6")
    default: Issue.record("Unknown mutation")
    }
    if mutation != "missing" { pagination["next"] = .string(link) }
    fields["pagination"] = .object(pagination)
    let mock = MockTransport(results: [
      .success(Response(body: try JSONEncoder().encode(fields), status: .ok))
    ])
    let query = try CRSReportQuery(
      fromDateTime: "2026-10-03T00:00:00Z", limit: 5, toDateTime: "2026-10-04T00:00:00Z")
    var items = client(mock).crsReports(matching: query).makeAsyncIterator()
    let failure = await #expect(throws: CongressDataError.self) { _ = try await items.next() }
    if case .invalidContinuation? = failure {
    } else {
      Issue.record("Expected invalid continuation")
    }
    #expect(try await items.next() == nil)
    #expect(mock.requests.count == 1)
  }

  @Test("CRS traversals retain later quota failures")
  func crsTraversalsRetainLaterQuotaFailures() async throws {
    let mock = MockTransport(results: [
      .success(Response(body: try Fixture.crs_reports_day_first.data(), status: .ok)),
      .success(Response(headers: [.retryAfter: "60"], status: .tooManyRequests)),
    ])
    let query = try CRSReportQuery(
      fromDateTime: "2026-10-03T00:00:00Z", limit: 5, toDateTime: "2026-10-04T00:00:00Z")
    var pages = client(mock).crsReportPages(matching: query).makeAsyncIterator()
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

  @Test("Recorded CRS chains follow exact links and terminate")
  func recordedCRSChainsFollowExactLinksAndTerminate() async throws {
    let bodies = try [Fixture.crs_reports_day_first, .crs_reports_day_terminal].map {
      try $0.data()
    }
    let paths = [
      "/v3/crsreport?format=json&fromDateTime=2026-10-03T00:00:00Z&limit=5&offset=0&toDateTime=2026-10-04T00:00:00Z",
      "/v3/crsreport?fromDateTime=2026-10-03T00:00:00Z&toDateTime=2026-10-04T00:00:00Z&offset=5&limit=5&format=json",
    ]
    let recorded = Dictionary(uniqueKeysWithValues: zip(paths, bodies))
    let mock = MockTransport()
    mock.setHandler(forPath: "/v3/crsreport") { request in
      guard let path = request.path, let body = recorded[path] else {
        return .success(MockTransport.Answer(Response(status: .notFound)))
      }
      return .success(MockTransport.Answer(Response(body: body, status: .ok)))
    }
    let query = try CRSReportQuery(
      fromDateTime: "2026-10-03T00:00:00Z", limit: 5, toDateTime: "2026-10-04T00:00:00Z")
    var pages = client(mock).crsReportPages(matching: query).makeAsyncIterator()
    for index in bodies.indices {
      let receipt = try #require(try await pages.next())
      #expect(receipt.body == bodies[index])
      #expect(receipt.value.pagination.count == 9)
      #expect(mock.requests.map(\.request.path) == Array(paths.prefix(index + 1)))
    }
    #expect(try await pages.next() == nil)
    var actual: [String] = []
    for try await member in client(mock).crsReports(matching: query) {
      actual.append(member.id)
    }
    #expect(
      actual == [
        "IF10199", "R49457", "R48568", "RS21852", "R49436", "R49432", "R45546", "R49477", "IF12892",
      ])
    #expect(mock.requests.map(\.request.path) == paths + paths)
  }

  private func client(_ mock: MockTransport) -> CongressDataClient {
    CongressDataClient(
      configuration: .init(apiKey: "test-key", userAgent: "CongressTests"), transport: mock)
  }
}
