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
struct CommitteeBillTests {
  @Test("All Committee bill execution levels retrieve one response")
  func allCommitteeBillExecutionLevelsRetrieveOneResponse() async throws {
    let bytes = try Fixture.committee_house_hspw00_bills_chain_first.data()
    let mock = MockTransport(
      results: Array(repeating: .success(Response(body: bytes, status: .ok)), count: 6))
    let client = client(mock)
    let identifier = try CommitteeIdentifier(chamber: .house, code: "hspw00")
    let query = try CommitteeBillQuery(
      fromDateTime: "2015-12-07T16:53:38Z", limit: 60, toDateTime: "2015-12-07T16:53:40Z")
    let stored = CongressRequest.committeeBills(for: identifier, matching: query)
    let expected = try await client.value(for: stored)
    #expect(try await client.send(.committeeBills(for: identifier, matching: query)) == expected)
    var pages = client.committeeBillPages(for: identifier, matching: query).makeAsyncIterator()
    #expect(try await pages.next()?.value == expected)
    var items = client.committeeBills(for: identifier, matching: query).makeAsyncIterator()
    #expect(try await items.next() == expected.items.first)
    var custom = client.pages(
      for: CongressRequest(endpoint: .committeeBills(for: identifier, matching: query))
    )
    .makeAsyncIterator()
    #expect(try await custom.next()?.value == expected)
    #expect(try await custom.next() == nil)
    struct Consumer: Decodable, Sendable { let pagination: Pagination }
    let endpoint = try #require(
      Endpoint<Consumer>(path: Endpoint.committeeBills(for: identifier, matching: query).path))
    #expect(try await client.send(endpoint).pagination.count == 109)
    #expect(mock.requests.count == 6)
  }

  @Test("Committee bill items cancel before HTTP and while buffered")
  func committeeBillItemsCancelBeforeHTTPAndWhileBuffered() async throws {
    let identifier = try CommitteeIdentifier(chamber: .house, code: "hspw00")
    let query = try CommitteeBillQuery(
      fromDateTime: "2015-12-07T16:53:38Z", limit: 60, toDateTime: "2015-12-07T16:53:40Z")
    for buffered in [false, true] {
      let mock = MockTransport(results: [
        .success(
          Response(
            body: try Fixture.committee_house_hspw00_bills_chain_first.data(), status: .ok
          ))
      ])
      let items = client(mock).committeeBills(for: identifier, matching: query)
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

  @Test("Committee bill items fetch lazily and keep traversals independent")
  func committeeBillItemsFetchLazilyAndKeepTraversalsIndependent() async throws {
    let bytes = try Fixture.committee_house_hspw00_bills_chain_first.data()
    let mock = MockTransport(
      results: Array(repeating: .success(Response(body: bytes, status: .ok)), count: 3))
    let identifier = try CommitteeIdentifier(chamber: .house, code: "hspw00")
    let query = try CommitteeBillQuery(
      fromDateTime: "2015-12-07T16:53:38Z", limit: 60, toDateTime: "2015-12-07T16:53:40Z")
    let items = client(mock).committeeBills(for: identifier, matching: query)
    var a = items.makeAsyncIterator()
    var b = items.makeAsyncIterator()
    #expect(mock.requests.isEmpty)
    #expect(try await a.next()?.number == "40")
    #expect(try await a.next()?.number == "124")
    #expect(mock.requests.count == 1)
    #expect(try await b.next()?.number == "40")
    #expect(mock.requests.count == 2)
    for try await _ in items { break }
    #expect(mock.requests.count == 3)
    let key = try #require(HTTPField.Name("X-Api-Key"))
    for call in mock.requests {
      #expect(call.request.authority == "api.congress.gov")
      #expect(call.request.headerFields[key] == "test-key")
    }
  }

  @Test("Committee bill pages remain lazy independent and cancellation aware")
  func committeeBillPagesRemainLazyIndependentAndCancellationAware() async throws {
    let bytes = try Fixture.committee_house_hspw00_bills_chain_first.data()
    let mock = MockTransport(
      results: Array(repeating: .success(Response(body: bytes, status: .ok)), count: 2))
    let identifier = try CommitteeIdentifier(chamber: .house, code: "hspw00")
    let query = try CommitteeBillQuery(
      fromDateTime: "2015-12-07T16:53:38Z", limit: 60, toDateTime: "2015-12-07T16:53:40Z")
    let pages = client(mock).committeeBillPages(for: identifier, matching: query)
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
    "Committee bill traversal rejects changed scope filters and paging",
    arguments: ["filter", "limit", "scope"])
  func committeeBillTraversalRejectsChangedScopeFiltersAndPaging(mutation: String) async throws {
    // Deliberate rejection mutations of recorded metadata.
    var fields = try JSONDecoder().decode(
      [String: JSONValue].self,
      from: Fixture.committee_house_hspw00_bills_chain_first.data())
    var pagination = try #require(fields["pagination"]?.object)
    var next = try #require(pagination["next"]?.string)
    switch mutation {
    case "filter": next = next.replacingOccurrences(of: "16:53:38Z", with: "16:53:39Z")
    case "limit": next = next.replacingOccurrences(of: "limit=60", with: "limit=61")
    case "scope": next = next.replacingOccurrences(of: "/house/hspw00", with: "/senate/ssju00")
    default: Issue.record("Unknown mutation")
    }
    pagination["next"] = .string(next)
    fields["pagination"] = .object(pagination)
    let mock = MockTransport(results: [
      .success(Response(body: try JSONEncoder().encode(fields), status: .ok))
    ])
    let identifier = try CommitteeIdentifier(chamber: .house, code: "hspw00")
    let query = try CommitteeBillQuery(
      fromDateTime: "2015-12-07T16:53:38Z", limit: 60, toDateTime: "2015-12-07T16:53:40Z")
    var items = client(mock).committeeBills(for: identifier, matching: query).makeAsyncIterator()
    let failure = await #expect(throws: CongressDataError.self) { _ = try await items.next() }
    if case .invalidContinuation? = failure {
    } else {
      Issue.record("Expected invalid continuation")
    }
    #expect(try await items.next() == nil)
    #expect(mock.requests.count == 1)
  }

  @Test("Committee bill traversals retain later quota failures")
  func committeeBillTraversalsRetainLaterQuotaFailures() async throws {
    let mock = MockTransport(results: [
      .success(
        Response(
          body: try Fixture.committee_house_hspw00_bills_chain_first.data(), status: .ok)),
      .success(Response(headers: [.retryAfter: "60"], status: .tooManyRequests)),
    ])
    let identifier = try CommitteeIdentifier(chamber: .house, code: "hspw00")
    let query = try CommitteeBillQuery(
      fromDateTime: "2015-12-07T16:53:38Z", limit: 60, toDateTime: "2015-12-07T16:53:40Z")
    var pages = client(mock).committeeBillPages(for: identifier, matching: query)
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

  @Test("Recorded committee bill chains follow exact links and terminate")
  func recordedCommitteeBillChainsFollowExactLinksAndTerminate() async throws {
    let bodies = try [
      Fixture.committee_house_hspw00_bills_chain_first,
      .committee_house_hspw00_bills_chain_terminal,
    ].map {
      try $0.data()
    }
    let paths = [
      "/v3/committee/house/hspw00/bills?format=json&fromDateTime=2015-12-07T16:53:38Z&limit=60&offset=0&toDateTime=2015-12-07T16:53:40Z",
      "/v3/committee/house/hspw00/bills?fromDateTime=2015-12-07T16:53:38Z&toDateTime=2015-12-07T16:53:40Z&offset=60&limit=60&format=json",
    ]
    let recorded = Dictionary(uniqueKeysWithValues: zip(paths, bodies))
    let mock = MockTransport()
    mock.setHandler(forPath: "/v3/committee/house/hspw00/bills") { request in
      guard let path = request.path, let body = recorded[path] else {
        return .success(MockTransport.Answer(Response(status: .notFound)))
      }
      return .success(MockTransport.Answer(Response(body: body, status: .ok)))
    }
    let identifier = try CommitteeIdentifier(chamber: .house, code: "hspw00")
    let query = try CommitteeBillQuery(
      fromDateTime: "2015-12-07T16:53:38Z", limit: 60, toDateTime: "2015-12-07T16:53:40Z")
    var pages = client(mock).committeeBillPages(for: identifier, matching: query)
      .makeAsyncIterator()
    for index in bodies.indices {
      let receipt = try #require(try await pages.next())
      #expect(receipt.body == bodies[index])
      #expect(receipt.value.pagination.count == 109)
      #expect(mock.requests.map(\.request.path) == Array(paths.prefix(index + 1)))
    }
    #expect(try await pages.next() == nil)
    var actual: [CommitteeBill] = []
    for try await bill in client(mock).committeeBills(for: identifier, matching: query) {
      actual.append(bill)
    }
    let expected = try bodies.flatMap {
      try JSONDecoder().decode(CommitteeBillPage.self, from: $0).items
    }
    #expect(actual == expected)
    #expect(actual.count == 109)
    #expect(mock.requests.map(\.request.path) == paths + paths)
  }

  private func client(_ mock: MockTransport) -> CongressDataClient {
    CongressDataClient(
      configuration: .init(apiKey: "test-key", userAgent: "CongressTests"), transport: mock)
  }
}
