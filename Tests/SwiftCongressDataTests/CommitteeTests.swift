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
struct CommitteeTests {
  @Test("All Committee execution levels retrieve one response")
  func allCommitteeExecutionLevelsRetrieveOneResponse() async throws {
    let bytes = try Fixture.committee_directory_congress_119_joint_chain_first.data()
    let mock = MockTransport(
      results: Array(repeating: .success(Response(body: bytes, status: .ok)), count: 6))
    let client = client(mock)
    let query = try CommitteeQuery(
      limit: 5, scope: .congressChamber(chamber: .joint, congress: 119))
    let stored = CongressRequest.committees(matching: query)
    let expected = try await client.value(for: stored)
    #expect(try await client.send(.committees(matching: query)) == expected)
    var pages = client.committeePages(matching: query).makeAsyncIterator()
    #expect(try await pages.next()?.value == expected)
    var items = client.committees(matching: query).makeAsyncIterator()
    #expect(try await items.next() == expected.items.first)
    var custom = client.pages(for: CongressRequest(endpoint: .committees(matching: query)))
      .makeAsyncIterator()
    #expect(try await custom.next()?.value == expected)
    #expect(try await custom.next() == nil)
    struct Consumer: Decodable, Sendable { let pagination: Pagination }
    let endpoint = try #require(Endpoint<Consumer>(path: Endpoint.committees(matching: query).path))
    #expect(try await client.send(endpoint).pagination.count == 9)
    #expect(mock.requests.count == 6)
  }

  @Test("Committee detail conveniences retain scope without fetching resources")
  func committeeDetailConveniencesRetainScopeWithoutFetchingResources() async throws {
    let bytes = try Fixture.committee_118_house_hspw00.data()
    let mock = MockTransport(
      results: Array(repeating: .success(Response(body: bytes, status: .ok)), count: 3))
    let client = client(mock)
    let identifier = try CommitteeIdentifier(chamber: .house, code: "hspw00")
    let expected = try await client.committee(identifier, congress: 118)
    #expect(try await client.value(for: .committee(identifier, congress: 118)) == expected)
    #expect(try await client.send(.committee(identifier, congress: 118)) == expected)
    #expect(
      mock.requests.map(\.request.path)
        == Array(repeating: "/v3/committee/118/house/hspw00?format=json", count: 3))
  }

  @Test("Committee invalid Congress fails before HTTP")
  func committeeInvalidCongressFailsBeforeHTTP() async throws {
    let mock = MockTransport()
    let identifier = try CommitteeIdentifier(chamber: .house, code: "hspw00")
    for congress in [0, -1] {
      let failure = await #expect(throws: CongressDataError.self) {
        _ = try await client(mock).committee(identifier, congress: congress)
      }
      if case .invalidInput(.invalidQuery)? = failure {
      } else {
        Issue.record("Expected invalid input")
      }
    }
    #expect(mock.requests.isEmpty)
  }

  @Test("Committee items cancel before HTTP and while buffered")
  func committeeItemsCancelBeforeHTTPAndWhileBuffered() async throws {
    let query = try CommitteeQuery(
      limit: 5, scope: .congressChamber(chamber: .joint, congress: 119))
    for buffered in [false, true] {
      let mock = MockTransport(results: [
        .success(
          Response(
            body: try Fixture.committee_directory_congress_119_joint_chain_first.data(), status: .ok
          ))
      ])
      let items = client(mock).committees(matching: query)
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

  @Test("Committee items fetch lazily and keep traversals independent")
  func committeeItemsFetchLazilyAndKeepTraversalsIndependent() async throws {
    let bytes = try Fixture.committee_directory_congress_119_joint_chain_first.data()
    let mock = MockTransport(
      results: Array(repeating: .success(Response(body: bytes, status: .ok)), count: 3))
    let query = try CommitteeQuery(
      limit: 5, scope: .congressChamber(chamber: .joint, congress: 119))
    let items = client(mock).committees(matching: query)
    var a = items.makeAsyncIterator()
    var b = items.makeAsyncIterator()
    #expect(mock.requests.isEmpty)
    #expect(try await a.next()?.systemCode == "jcuc00")
    #expect(try await a.next()?.systemCode == "jjec00")
    #expect(mock.requests.count == 1)
    #expect(try await b.next()?.systemCode == "jcuc00")
    #expect(mock.requests.count == 2)
    for try await _ in items { break }
    #expect(mock.requests.count == 3)
    let key = try #require(HTTPField.Name("X-Api-Key"))
    for call in mock.requests {
      #expect(call.request.authority == "api.congress.gov")
      #expect(call.request.headerFields[key] == "test-key")
    }
  }

  @Test("Committee recorded count mismatch fails before yielding but decodes once")
  func committeeRecordedCountMismatchFailsBeforeYieldingButDecodesOnce() async throws {
    let bytes = try Fixture.committee_directory_congress_119.data()
    let mock = MockTransport(
      results: Array(repeating: .success(Response(body: bytes, status: .ok)), count: 3))
    let client = client(mock)
    let query = try CommitteeQuery(limit: 250, scope: .congress(119))
    let single = try await client.value(for: .committees(matching: query))
    #expect(single.items.count == 236)
    #expect(single.pagination.count == 238)
    var pages = client.committeePages(matching: query).makeAsyncIterator()
    let pageFailure = await #expect(throws: CongressDataError.self) { _ = try await pages.next() }
    if case .invalidContinuation? = pageFailure {
    } else {
      Issue.record("Expected invalid continuation")
    }
    #expect(try await pages.next() == nil)
    var items = client.committees(matching: query).makeAsyncIterator()
    let itemFailure = await #expect(throws: CongressDataError.self) { _ = try await items.next() }
    if case .invalidContinuation? = itemFailure {
    } else {
      Issue.record("Expected invalid continuation")
    }
    #expect(try await items.next() == nil)
    #expect(mock.requests.count == 3)
  }

  @Test(
    "Committee traversal rejects changed scope filters and paging",
    arguments: ["filter", "limit", "scope"])
  func committeeTraversalRejectsChangedScopeFiltersAndPaging(mutation: String) async throws {
    // Deliberate rejection mutations of recorded metadata.
    var fields = try JSONDecoder().decode(
      [String: JSONValue].self,
      from: Fixture.committee_directory_congress_119_joint_chain_first.data())
    var pagination = try #require(fields["pagination"]?.object)
    var next = try #require(pagination["next"]?.string)
    switch mutation {
    case "filter": next += "&fromDateTime=2026-01-01T00:00:00Z"
    case "limit": next = next.replacingOccurrences(of: "limit=5", with: "limit=6")
    case "scope": next = next.replacingOccurrences(of: "/119/joint", with: "/118/joint")
    default: Issue.record("Unknown mutation")
    }
    pagination["next"] = .string(next)
    fields["pagination"] = .object(pagination)
    let mock = MockTransport(results: [
      .success(Response(body: try JSONEncoder().encode(fields), status: .ok))
    ])
    let query = try CommitteeQuery(
      limit: 5, scope: .congressChamber(chamber: .joint, congress: 119))
    var items = client(mock).committees(matching: query).makeAsyncIterator()
    let failure = await #expect(throws: CongressDataError.self) { _ = try await items.next() }
    if case .invalidContinuation? = failure {
    } else {
      Issue.record("Expected invalid continuation")
    }
    #expect(try await items.next() == nil)
    #expect(mock.requests.count == 1)
  }

  @Test("Committee traversals retain later quota failures")
  func committeeTraversalsRetainLaterQuotaFailures() async throws {
    let mock = MockTransport(results: [
      .success(
        Response(
          body: try Fixture.committee_directory_congress_119_joint_chain_first.data(), status: .ok)),
      .success(Response(headers: [.retryAfter: "60"], status: .tooManyRequests)),
    ])
    let query = try CommitteeQuery(
      limit: 5, scope: .congressChamber(chamber: .joint, congress: 119))
    var pages = client(mock).committeePages(matching: query).makeAsyncIterator()
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

  @Test("Recorded Committee chains follow exact links and terminate")
  func recordedCommitteeChainsFollowExactLinksAndTerminate() async throws {
    let bodies = try [
      Fixture.committee_directory_congress_119_joint_chain_first,
      .committee_directory_congress_119_joint_chain_terminal,
    ].map {
      try $0.data()
    }
    let paths = [
      "/v3/committee/119/joint?format=json&limit=5&offset=0",
      "/v3/committee/119/joint?offset=5&limit=5&format=json",
    ]
    let recorded = Dictionary(uniqueKeysWithValues: zip(paths, bodies))
    let mock = MockTransport()
    mock.setHandler(forPath: "/v3/committee/119/joint") { request in
      guard let path = request.path, let body = recorded[path] else {
        return .success(MockTransport.Answer(Response(status: .notFound)))
      }
      return .success(MockTransport.Answer(Response(body: body, status: .ok)))
    }
    let query = try CommitteeQuery(
      limit: 5, scope: .congressChamber(chamber: .joint, congress: 119))
    var pages = client(mock).committeePages(matching: query).makeAsyncIterator()
    for index in bodies.indices {
      let receipt = try #require(try await pages.next())
      #expect(receipt.body == bodies[index])
      #expect(receipt.value.pagination.count == 9)
      #expect(mock.requests.map(\.request.path) == Array(paths.prefix(index + 1)))
    }
    #expect(try await pages.next() == nil)
    var actual: [String] = []
    for try await member in client(mock).committees(matching: query) {
      actual.append(member.systemCode)
    }
    let expected = try bodies.flatMap {
      try JSONDecoder().decode(CommitteePage.self, from: $0).items
    }
    #expect(actual == expected.map(\.systemCode))
    #expect(actual.count == 9)
    #expect(mock.requests.map(\.request.path) == paths + paths)
  }

  private func client(_ mock: MockTransport) -> CongressDataClient {
    CongressDataClient(
      configuration: .init(apiKey: "test-key", userAgent: "CongressTests"), transport: mock)
  }
}
