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
struct CommitteeSenateCommunicationTests {
  @Test("All Committee Senate communication execution levels retrieve one response")
  func allCommitteeSenateCommunicationExecutionLevelsRetrieveOneResponse() async throws {
    let bytes = try Fixture.committee_senate_slet00_senate_communications_chain_first.data()
    let mock = MockTransport(
      results: Array(repeating: .success(Response(body: bytes, status: .ok)), count: 10))
    let client = client(mock)
    let identifier = try CommitteeIdentifier(chamber: .senate, code: "slet00")
    let query = try CongressQuery(limit: 11)
    let stored = try CongressRequest.committeeSenateCommunications(for: identifier, page: query)
    let expected = try await client.value(for: stored)
    #expect(mock.requests.count == 1)
    let archive = try CongressRequest.committeeSenateCommunicationsForArchive(
      for: identifier, page: query)
    #expect(try await client.value(for: archive) == expected)
    #expect(mock.requests.count == 2)
    #expect(
      mock.requests.last?.request.path
        == (try Endpoint.committeeSenateCommunications(for: identifier, page: query).path))
    #expect(
      try await client.value(for: .committeeSenateCommunications(for: identifier, page: query))
        == expected)
    #expect(
      try await client.send(.committeeSenateCommunications(for: identifier, page: query))
        == expected
    )
    var pages = try client.committeeSenateCommunicationPages(for: identifier, page: query)
      .makeAsyncIterator()
    #expect(try await pages.next()?.value == expected)
    var items = try client.committeeSenateCommunications(for: identifier, page: query)
      .makeAsyncIterator()
    #expect(try await items.next() == expected.items.first)
    var genericPages = client.pages(for: stored).makeAsyncIterator()
    #expect(try await genericPages.next()?.value == expected)
    var genericItems = client.items(for: stored).makeAsyncIterator()
    #expect(try await genericItems.next() == expected.items.first)
    var custom = try client.pages(
      for: CongressRequest(endpoint: .committeeSenateCommunications(for: identifier, page: query))
    )
    .makeAsyncIterator()
    #expect(try await custom.next()?.value == expected)
    #expect(try await custom.next() == nil)
    struct Consumer: Decodable, Sendable { let pagination: Pagination }
    let endpoint = try #require(
      Endpoint<Consumer>(
        path: Endpoint.committeeSenateCommunications(for: identifier, page: query).path))
    #expect(try await client.send(endpoint).pagination.count == 31)
    #expect(mock.requests.count == 10)
  }

  @Test("Committee Senate communication items cancel before HTTP and while buffered")
  func committeeSenateCommunicationItemsCancelBeforeHTTPAndWhileBuffered() async throws {
    let identifier = try CommitteeIdentifier(chamber: .senate, code: "slet00")
    let query = try CongressQuery(limit: 11)
    for buffered in [false, true] {
      let mock = MockTransport(results: [
        .success(
          Response(
            body: try Fixture.committee_senate_slet00_senate_communications_chain_first.data(),
            status: .ok
          ))
      ])
      let items = try client(mock).committeeSenateCommunications(for: identifier, page: query)
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

  @Test("Committee Senate communication items fetch lazily and keep traversals independent")
  func committeeSenateCommunicationItemsFetchLazilyAndKeepTraversalsIndependent() async throws {
    let bytes = try Fixture.committee_senate_slet00_senate_communications_chain_first.data()
    let mock = MockTransport(
      results: Array(repeating: .success(Response(body: bytes, status: .ok)), count: 4))
    let identifier = try CommitteeIdentifier(chamber: .senate, code: "slet00")
    let query = try CongressQuery(limit: 11)
    let items = try client(mock).committeeSenateCommunications(for: identifier, page: query)
    var a = items.makeAsyncIterator()
    var b = items.makeAsyncIterator()
    #expect(mock.requests.isEmpty)
    #expect(try await a.next()?.number == 6935)
    #expect(try await a.next()?.number == 189)
    #expect(mock.requests.count == 1)
    for _ in 2..<11 { _ = try await a.next() }
    #expect(mock.requests.count == 1)
    #expect(try await b.next()?.number == 6935)
    #expect(mock.requests.count == 2)
    var bufferedCount = 0
    for try await _ in items {
      bufferedCount += 1
      if bufferedCount == 11 { break }
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

  @Test("Committee Senate communication pages remain lazy independent and cancellation aware")
  func committeeSenateCommunicationPagesRemainLazyIndependentAndCancellationAware() async throws {
    let bytes = try Fixture.committee_senate_slet00_senate_communications_chain_first.data()
    let mock = MockTransport(
      results: Array(repeating: .success(Response(body: bytes, status: .ok)), count: 3))
    let identifier = try CommitteeIdentifier(chamber: .senate, code: "slet00")
    let query = try CongressQuery(limit: 11)
    let pages = try client(mock).committeeSenateCommunicationPages(for: identifier, page: query)
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
    "Committee Senate communication traversal rejects changed scope filters and paging",
    arguments: [
      "count", "credential", "duplicate", "filter", "limit", "malformed", "missing-next", "offset",
      "origin", "scope",
    ])
  func committeeSenateCommunicationTraversalRejectsChangedScopeFiltersAndPaging(mutation: String)
    async throws
  {
    // Deliberate rejection mutations of recorded metadata.
    var fields = try JSONDecoder().decode(
      [String: JSONValue].self,
      from: Fixture.committee_senate_slet00_senate_communications_chain_first.data())
    var pagination = try #require(fields["pagination"]?.object)
    var next = try #require(pagination["next"]?.string)
    switch mutation {
    case "count": pagination["count"] = .number(1)
    case "credential": next += "&api_key=secret"
    case "duplicate": next += "&offset=11"
    case "filter": next += "&fromDateTime=2020-01-01T00:00:00Z"
    case "limit": next = next.replacingOccurrences(of: "limit=11", with: "limit=12")
    case "malformed": next = "not a URL"
    case "missing-next": break
    case "offset": next = next.replacingOccurrences(of: "offset=11", with: "offset=0")
    case "origin": next = next.replacingOccurrences(of: "api.congress.gov", with: "example.com")
    case "scope": next = next.replacingOccurrences(of: "/senate/slet00", with: "/senate/ssju00")
    default: Issue.record("Unknown mutation")
    }
    pagination["next"] = mutation == "missing-next" ? nil : .string(next)
    fields["pagination"] = .object(pagination)
    let mock = MockTransport(results: [
      .success(Response(body: try JSONEncoder().encode(fields), status: .ok))
    ])
    let identifier = try CommitteeIdentifier(chamber: .senate, code: "slet00")
    let query = try CongressQuery(limit: 11)
    var items = try client(mock).committeeSenateCommunications(for: identifier, page: query)
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
    "Committee Senate communication traversals reject a repeated later next link before yielding")
  func committeeSenateCommunicationTraversalsRejectARepeatedLaterNextLinkBeforeYielding()
    async throws
  {
    let first = try Fixture.committee_senate_slet00_senate_communications_chain_first.data()
    var fields = try JSONDecoder().decode(
      [String: JSONValue].self,
      from: Fixture.committee_senate_slet00_senate_communications_chain_next.data())
    var pagination = try #require(fields["pagination"]?.object)
    let initial = try JSONDecoder().decode(CommitteeSenateCommunicationPage.self, from: first)
    pagination["next"] = initial.rawFields["pagination"]?.object?["next"]
    fields["pagination"] = .object(pagination)
    let mock = MockTransport(results: [
      .success(Response(body: first, status: .ok)),
      .success(Response(body: try JSONEncoder().encode(fields), status: .ok)),
    ])
    let identifier = try CommitteeIdentifier(chamber: .senate, code: "slet00")
    let query = try CongressQuery(limit: 11)
    var pages = try client(mock).committeeSenateCommunicationPages(for: identifier, page: query)
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

  @Test("Committee Senate communication traversals retain later quota failures")
  func committeeSenateCommunicationTraversalsRetainLaterQuotaFailures() async throws {
    let mock = MockTransport(results: [
      .success(
        Response(
          body: try Fixture.committee_senate_slet00_senate_communications_chain_first.data(),
          status: .ok)),
      .success(Response(headers: [.retryAfter: "60"], status: .tooManyRequests)),
    ])
    let identifier = try CommitteeIdentifier(chamber: .senate, code: "slet00")
    let query = try CongressQuery(limit: 11)
    var pages = try client(mock).committeeSenateCommunicationPages(for: identifier, page: query)
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

  @Test("Invalid committee Senate communication chambers fail before HTTP")
  func invalidCommitteeSenateCommunicationChambersFailBeforeHTTP() throws {
    let mock = MockTransport()
    let client = client(mock)
    for chamber in [CommitteeChamber.house, .joint] {
      let identifier = try CommitteeIdentifier(chamber: chamber, code: "safe00")
      #expect(throws: CongressInputError.unsupportedCommitteeResource) {
        try CongressRequest.committeeSenateCommunications(for: identifier)
      }
      #expect(throws: CongressInputError.unsupportedCommitteeResource) {
        try Endpoint.committeeSenateCommunications(for: identifier)
      }
      #expect(throws: CongressInputError.unsupportedCommitteeResource) {
        try client.committeeSenateCommunicationPages(for: identifier)
      }
      #expect(throws: CongressInputError.unsupportedCommitteeResource) {
        try client.committeeSenateCommunications(for: identifier)
      }
    }
    #expect(mock.requests.isEmpty)
  }

  @Test("Recorded committee Senate communication chains follow exact links and terminate")
  func recordedCommitteeSenateCommunicationChainsFollowExactLinksAndTerminate() async throws {
    let bodies = try [
      Fixture.committee_senate_slet00_senate_communications_chain_first,
      .committee_senate_slet00_senate_communications_chain_next,
      .committee_senate_slet00_senate_communications_chain_terminal,
    ].map {
      try $0.data()
    }
    let paths = [
      "/v3/committee/senate/slet00/senate-communication?format=json&limit=11&offset=0",
      "/v3/committee/senate/slet00/senate-communication?offset=11&limit=11&format=json",
      "/v3/committee/senate/slet00/senate-communication?offset=22&limit=11&format=json",
    ]
    let recorded = Dictionary(uniqueKeysWithValues: zip(paths, bodies))
    let mock = MockTransport()
    mock.setHandler(forPath: "/v3/committee/senate/slet00/senate-communication") { request in
      guard let path = request.path, let body = recorded[path] else {
        return .success(MockTransport.Answer(Response(status: .notFound)))
      }
      return .success(MockTransport.Answer(Response(body: body, status: .ok)))
    }
    let identifier = try CommitteeIdentifier(chamber: .senate, code: "slet00")
    let query = try CongressQuery(limit: 11)
    var pages = try client(mock).committeeSenateCommunicationPages(for: identifier, page: query)
      .makeAsyncIterator()
    for index in bodies.indices {
      let receipt = try #require(try await pages.next())
      #expect(receipt.body == bodies[index])
      #expect(receipt.value.pagination.count == 31)
      #expect(mock.requests.map(\.request.path) == Array(paths.prefix(index + 1)))
    }
    #expect(try await pages.next() == nil)
    var actual: [CommitteeSenateCommunication] = []
    for try await communication in try client(mock).committeeSenateCommunications(
      for: identifier, page: query)
    {
      actual.append(communication)
    }
    let expected = try bodies.flatMap {
      try JSONDecoder().decode(CommitteeSenateCommunicationPage.self, from: $0).items
    }
    #expect(actual == expected)
    #expect(actual.count == 31)
    #expect(actual.filter { $0.communicationType.code == "EC" }.count == 29)
    #expect(actual.filter { $0.communicationType.code == "PM" }.count == 1)
    #expect(actual.filter { $0.communicationType.code == "POM" }.count == 1)
    #expect(actual.first?.referralDate == "2014-09-15")
    #expect(actual.first?.updateDate == "2019-02-19")
    #expect(mock.requests.map(\.request.path) == paths + paths)
  }

  private func client(_ mock: MockTransport) -> CongressDataClient {
    CongressDataClient(
      configuration: .init(apiKey: "test-key", userAgent: "CongressTests"), transport: mock)
  }
}

private extension CongressRequest where Response == CommitteeSenateCommunicationPage {
  static func committeeSenateCommunicationsForArchive(
    for identifier: CommitteeIdentifier, page query: CongressQuery
  ) throws(CongressInputError) -> Self {
    try .committeeSenateCommunications(for: identifier, page: query)
  }
}
