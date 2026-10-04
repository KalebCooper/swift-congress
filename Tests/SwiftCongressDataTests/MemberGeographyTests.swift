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

extension CongressRequest where Response == MemberPage {
  static var alaskaMembersConsumerExample: Self {
    get throws {
      try .members(
        matching: MemberGeographyQuery(
          currentMember: true, scope: .state(limit: 2, stateCode: "AK")))
    }
  }
}

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct MemberGeographyTests {
  @Test("All geographic execution levels retrieve one response")
  func allGeographicExecutionLevelsRetrieveOneResponse() async throws {
    let bytes = try Fixture.members_ak_current_first.data()
    let mock = MockTransport(
      results: Array(repeating: .success(Response(body: bytes, status: .ok)), count: 8))
    let client = client(mock)
    let query = try MemberGeographyQuery(
      currentMember: true, scope: .state(limit: 2, stateCode: "AK"))
    let stored = CongressRequest.members(matching: query)
    let expected = try await client.value(for: stored)
    #expect(try await client.value(for: .alaskaMembersConsumerExample) == expected)
    #expect(try await client.value(for: .members(matching: query)) == expected)
    #expect(try await client.send(.members(matching: query)) == expected)
    var pages = client.memberPages(matching: query).makeAsyncIterator()
    #expect(try await pages.next()?.value == expected)
    var items = client.members(matching: query).makeAsyncIterator()
    #expect(try await items.next() == expected.items.first)
    var custom = client.pages(for: CongressRequest(endpoint: .members(matching: query)))
      .makeAsyncIterator()
    #expect(try await custom.next()?.value == expected)
    #expect(try await custom.next() == nil)
    struct Consumer: Decodable, Sendable { let pagination: Pagination }
    let endpoint = try #require(Endpoint<Consumer>(path: Endpoint.members(matching: query).path))
    #expect(try await client.send(endpoint).pagination.count == 3)
    #expect(mock.requests.count == 8)
  }

  @Test("Geographic items cancel before HTTP and while buffered")
  func geographicItemsCancelBeforeHTTPAndWhileBuffered() async throws {
    let query = try MemberGeographyQuery(
      currentMember: true, scope: .state(limit: 2, stateCode: "AK"))
    for buffered in [false, true] {
      let mock = MockTransport(results: [
        .success(Response(body: try Fixture.members_ak_current_first.data(), status: .ok))
      ])
      let items = client(mock).members(matching: query)
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

  @Test("Geographic items fetch lazily and keep traversals independent")
  func geographicItemsFetchLazilyAndKeepTraversalsIndependent() async throws {
    let bytes = try Fixture.members_ak_current_first.data()
    let mock = MockTransport(
      results: Array(repeating: .success(Response(body: bytes, status: .ok)), count: 3))
    let query = try MemberGeographyQuery(
      currentMember: true, scope: .state(limit: 2, stateCode: "AK"))
    let items = client(mock).members(matching: query)
    var a = items.makeAsyncIterator()
    var b = items.makeAsyncIterator()
    #expect(mock.requests.isEmpty)
    #expect(try await a.next()?.bioguideId == "B001323")
    #expect(try await a.next()?.bioguideId == "S001198")
    #expect(mock.requests.count == 1)
    #expect(try await b.next()?.bioguideId == "B001323")
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
    "Geographic traversal rejects mutated links counts and page sizes",
    arguments: [
      "count", "credentials", "district", "duplicate", "filter", "limit", "malformed",
      "missing", "origin", "overrun", "repeated", "skipped", "state",
    ])
  func geographicTraversalRejectsMutatedLinksCountsAndPageSizes(mutation: String) async throws {
    // Labeled mutations of an official response are rejection tests, not source evidence.
    var fields = try JSONDecoder().decode(
      [String: JSONValue].self, from: Fixture.members_ak_current_first.data())
    var pagination = try #require(fields["pagination"]?.object)
    var link = try #require(pagination["next"]?.string)
    switch mutation {
    case "count": pagination["count"] = .number(1)
    case "credentials": link += "&api_key=secret"
    case "district": link = link.replacingOccurrences(of: "/AK?", with: "/AK/0?")
    case "duplicate": link += "&offset=2"
    case "filter":
      link = link.replacingOccurrences(of: "currentMember=true", with: "currentMember=false")
    case "limit": link = link.replacingOccurrences(of: "limit=2", with: "limit=3")
    case "malformed": link = "not a URL"
    case "missing": pagination.removeValue(forKey: "next")
    case "origin": link = link.replacingOccurrences(of: "api.congress.gov", with: "example.com")
    case "overrun":
      var rows = try #require(fields["members"]?.array)
      rows.append(rows[0])
      fields["members"] = .array(rows)
    case "repeated": link = link.replacingOccurrences(of: "offset=2", with: "offset=0")
    case "skipped": link = link.replacingOccurrences(of: "offset=2", with: "offset=3")
    case "state": link = link.replacingOccurrences(of: "/AK?", with: "/NY?")
    default: Issue.record("Unknown mutation")
    }
    if mutation != "missing" { pagination["next"] = .string(link) }
    fields["pagination"] = .object(pagination)
    let mock = MockTransport(results: [
      .success(Response(body: try JSONEncoder().encode(fields), status: .ok))
    ])
    let query = try MemberGeographyQuery(
      currentMember: true, scope: .state(limit: 2, stateCode: "AK"))
    var items = client(mock).members(matching: query).makeAsyncIterator()
    let failure = await #expect(throws: CongressDataError.self) { _ = try await items.next() }
    if case .invalidContinuation? = failure {
    } else {
      Issue.record("Expected invalid continuation")
    }
    #expect(try await items.next() == nil)
    #expect(mock.requests.count == 1)
  }

  @Test("Geographic traversals retain later quota failures")
  func geographicTraversalsRetainLaterQuotaFailures() async throws {
    let mock = MockTransport(results: [
      .success(Response(body: try Fixture.members_ak_current_first.data(), status: .ok)),
      .success(Response(headers: [.retryAfter: "60"], status: .tooManyRequests)),
    ])
    let query = try MemberGeographyQuery(
      currentMember: true, scope: .state(limit: 2, stateCode: "AK"))
    var pages = client(mock).memberPages(matching: query).makeAsyncIterator()
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

  @Test("Recorded geographic chains follow exact links and terminate")
  func recordedGeographicChainsFollowExactLinksAndTerminate() async throws {
    let bodies = try [Fixture.members_ak_current_first, .members_ak_current_terminal].map {
      try $0.data()
    }
    let paths = [
      "/v3/member/AK?currentMember=true&format=json&limit=2",
      "/v3/member/AK?currentMember=true&offset=2&limit=2&format=json",
    ]
    let recorded = Dictionary(uniqueKeysWithValues: zip(paths, bodies))
    let mock = MockTransport()
    mock.setHandler(forPath: "/v3/member/AK") { request in
      guard let path = request.path, let body = recorded[path] else {
        return .success(MockTransport.Answer(Response(status: .notFound)))
      }
      return .success(MockTransport.Answer(Response(body: body, status: .ok)))
    }
    let query = try MemberGeographyQuery(
      currentMember: true, scope: .state(limit: 2, stateCode: "AK"))
    var pages = client(mock).memberPages(matching: query).makeAsyncIterator()
    for index in bodies.indices {
      let receipt = try #require(try await pages.next())
      #expect(receipt.body == bodies[index])
      #expect(receipt.value.pagination.count == 3)
      #expect(mock.requests.map(\.request.path) == Array(paths.prefix(index + 1)))
    }
    #expect(try await pages.next() == nil)
    var actual: [String] = []
    for try await member in client(mock).members(matching: query) {
      actual.append(member.bioguideId)
    }
    #expect(actual == ["B001323", "S001198", "M001153"])
    #expect(mock.requests.map(\.request.path) == paths + paths)
  }

  @Test("Recorded terminal district routes retain every member")
  func recordedTerminalDistrictRoutesRetainEveryMember() async throws {
    let scopes: [MemberGeographyQuery.Scope] = [
      .district(district: 0, stateCode: "AK"),
      .district(district: 0, stateCode: "DC"),
      .congressDistrict(congress: 118, district: 15, stateCode: "TX"),
    ]
    let fixtures: [Fixture] = [
      .members_ak_district0_current, .members_dc_district0_current, .members118_tx15_historical,
    ]
    for (index, scope) in scopes.enumerated() {
      let bytes = try fixtures[index].data()
      let expected = try JSONDecoder().decode(MemberPage.self, from: bytes)
      let mock = MockTransport(results: [.success(Response(body: bytes, status: .ok))])
      let query = try MemberGeographyQuery(currentMember: index < 2, scope: scope)
      var actual: [MemberSummary] = []
      for try await member in client(mock).members(matching: query) { actual.append(member) }
      #expect(actual == expected.items)
      #expect(mock.requests.count == 1)
      #expect(mock.requests.first?.request.path == Endpoint.members(matching: query).path)
    }
  }

  private func client(_ mock: MockTransport) -> CongressDataClient {
    CongressDataClient(
      configuration: .init(apiKey: "test-key", userAgent: "CongressTests"), transport: mock)
  }
}
