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

extension CongressRequest where Response == CosponsoredLegislationPage {
  static var cosponsoredLegislationConsumerExample: Self {
    get throws {
      try .cosponsoredLegislation(
        for: MemberIdentifier(rawValue: "C001136"), page: CongressQuery(limit: 80))
    }
  }
}

extension CongressRequest where Response == SponsoredLegislationPage {
  static var sponsoredLegislationConsumerExample: Self {
    get throws {
      try .sponsoredLegislation(
        for: MemberIdentifier(rawValue: "C001136"), page: CongressQuery(limit: 5))
    }
  }
}

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct MemberLegislationTests {
  @Test("All cosponsored legislation execution levels retain one response")
  func allCosponsoredLegislationExecutionLevelsRetainOneResponse() async throws {
    let bytes = try Fixture.member_c001136_cosponsored_legislation_first.data()
    let mock = MockTransport(
      results: Array(repeating: .success(Response(body: bytes, status: .ok)), count: 8))
    let client = client(mock)
    let member = try MemberIdentifier(rawValue: "C001136")
    let bounds = try CongressQuery(limit: 80)
    let stored = CongressRequest.cosponsoredLegislation(for: member, page: bounds)
    let expected = try await client.value(for: stored)
    #expect(try await client.value(for: .cosponsoredLegislationConsumerExample) == expected)
    #expect(
      try await client.value(for: .cosponsoredLegislation(for: member, page: bounds)) == expected)
    #expect(try await client.send(.cosponsoredLegislation(for: member, page: bounds)) == expected)
    var pages = client.cosponsoredLegislationPages(for: member, page: bounds).makeAsyncIterator()
    #expect(try await pages.next()?.value == expected)
    var items = client.cosponsoredLegislation(for: member, page: bounds).makeAsyncIterator()
    #expect(try await items.next() == expected.items.first)
    var custom = client.pages(
      for: CongressRequest(endpoint: .cosponsoredLegislation(for: member, page: bounds))
    ).makeAsyncIterator()
    #expect(try await custom.next()?.value == expected)
    #expect(try await custom.next() == nil)
    struct Consumer: Decodable, Sendable { let pagination: Pagination }
    let endpoint = try #require(
      Endpoint<Consumer>(path: Endpoint.cosponsoredLegislation(for: member, page: bounds).path))
    #expect(try await client.send(endpoint).pagination.count == 239)
    #expect(mock.requests.count == 8)
  }

  @Test("All sponsored legislation execution levels retain one response")
  func allSponsoredLegislationExecutionLevelsRetainOneResponse() async throws {
    let bytes = try Fixture.member_c001136_sponsored_legislation_first.data()
    let mock = MockTransport(
      results: Array(repeating: .success(Response(body: bytes, status: .ok)), count: 8))
    let client = client(mock)
    let member = try MemberIdentifier(rawValue: "C001136")
    let bounds = try CongressQuery(limit: 5)
    let stored = CongressRequest.sponsoredLegislation(for: member, page: bounds)
    let expected = try await client.value(for: stored)
    #expect(try await client.value(for: .sponsoredLegislationConsumerExample) == expected)
    #expect(
      try await client.value(for: .sponsoredLegislation(for: member, page: bounds)) == expected)
    #expect(try await client.send(.sponsoredLegislation(for: member, page: bounds)) == expected)
    var pages = client.sponsoredLegislationPages(for: member, page: bounds).makeAsyncIterator()
    #expect(try await pages.next()?.value == expected)
    var items = client.sponsoredLegislation(for: member, page: bounds).makeAsyncIterator()
    #expect(try await items.next() == expected.items.first)
    var custom = client.pages(
      for: CongressRequest(endpoint: .sponsoredLegislation(for: member, page: bounds))
    ).makeAsyncIterator()
    #expect(try await custom.next()?.value == expected)
    #expect(try await custom.next() == nil)
    struct Consumer: Decodable, Sendable { let pagination: Pagination }
    let endpoint = try #require(
      Endpoint<Consumer>(path: Endpoint.sponsoredLegislation(for: member, page: bounds).path))
    #expect(try await client.send(endpoint).pagination.count == 15)
    #expect(mock.requests.count == 8)
  }

  @Test("Both member legislation collections buffer lazily and keep iterators independent")
  func bothMemberLegislationCollectionsBufferLazilyAndKeepIteratorsIndependent() async throws {
    try await buffering(
      try .cosponsoredLegislationConsumerExample,
      fixture: .member_c001136_cosponsored_legislation_first)
    try await buffering(
      try .sponsoredLegislationConsumerExample, fixture: .member_c001136_sponsored_legislation_first
    )
  }

  @Test("Both member legislation collections cancel before HTTP and while buffered")
  func bothMemberLegislationCollectionsCancelBeforeHTTPAndWhileBuffered() async throws {
    try await cancellation(
      try .cosponsoredLegislationConsumerExample,
      fixture: .member_c001136_cosponsored_legislation_first)
    try await cancellation(
      try .sponsoredLegislationConsumerExample, fixture: .member_c001136_sponsored_legislation_first
    )
  }

  @Test("Both member legislation collections preserve later typed failures and quota headers")
  func bothMemberLegislationCollectionsPreserveLaterTypedFailuresAndQuotaHeaders() async throws {
    try await laterFailure(
      try .cosponsoredLegislationConsumerExample,
      fixture: .member_c001136_cosponsored_legislation_first)
    try await laterFailure(
      try .sponsoredLegislationConsumerExample, fixture: .member_c001136_sponsored_legislation_first
    )
  }

  @Test(
    "Invalid member legislation continuations fail before any record is yielded",
    arguments: [
      "origin", "path", "identity", "credentials", "duplicate", "repeated", "skipped",
      "malformed", "missing", "limit", "filter", "overrun",
    ])
  func invalidMemberLegislationContinuationsFailBeforeAnyRecordIsYielded(mutation: String)
    async throws
  {
    try await invalidContinuation(
      try .cosponsoredLegislationConsumerExample,
      fixture: .member_c001136_cosponsored_legislation_first, mutation: mutation)
    try await invalidContinuation(
      try .sponsoredLegislationConsumerExample,
      fixture: .member_c001136_sponsored_legislation_first, mutation: mutation)
  }

  @Test("Recorded member legislation chains preserve every page item and receipt")
  func recordedMemberLegislationChainsPreserveEveryPageItemAndReceipt() async throws {
    try await chain(
      try .cosponsoredLegislationConsumerExample, count: 239,
      fixtures: [
        .member_c001136_cosponsored_legislation_first, .member_c001136_cosponsored_legislation_next,
        .member_c001136_cosponsored_legislation_terminal,
      ], limit: 80, route: "cosponsored-legislation")
    try await chain(
      try .sponsoredLegislationConsumerExample, count: 15,
      fixtures: [
        .member_c001136_sponsored_legislation_first, .member_c001136_sponsored_legislation_next,
        .member_c001136_sponsored_legislation_terminal,
      ], limit: 5, route: "sponsored-legislation")
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

  private func chain<Page: CongressCollection & Equatable>(
    _ request: CongressRequest<Page>, count: Int, fixtures: [Fixture], limit: Int, route: String
  ) async throws where Page.Item == MemberLegislation {
    let bodies = try fixtures.map { try $0.data() }
    let decoded = try bodies.map { try JSONDecoder().decode(Page.self, from: $0) }
    let paths = [
      "/v3/member/C001136/\(route)?format=json&limit=\(limit)&offset=0",
      "/v3/member/C001136/\(route)?offset=\(limit)&limit=\(limit)&format=json",
      "/v3/member/C001136/\(route)?offset=\(limit * 2)&limit=\(limit)&format=json",
    ]
    #expect(decoded.map(\.pagination.count) == [count, count, count])
    #expect(decoded.last?.pagination.next == nil)
    let recorded = Dictionary(uniqueKeysWithValues: zip(paths, bodies))
    let mock = MockTransport()
    // Exact request targets answer only with the original captured bytes.
    mock.setHandler(forPath: "/v3/member/C001136/\(route)") { request in
      guard let path = request.path, let body = recorded[path] else {
        return .success(MockTransport.Answer(Response(status: .notFound)))
      }
      return .success(
        MockTransport.Answer(
          Response(body: body, headers: [.contentType: "application/json"], status: .ok)))
    }
    var pages = client(mock).pages(for: request).makeAsyncIterator()
    #expect(mock.requests.isEmpty)
    for index in bodies.indices {
      let receipt = try #require(try await pages.next())
      #expect(receipt.body == bodies[index])
      #expect(receipt.value == decoded[index])
      #expect(receipt.status == 200)
      #expect(
        receipt.headers.contains {
          $0.name.lowercased() == "content-type" && $0.value == "application/json"
        })
      #expect(mock.requests.map(\.request.path) == Array(paths.prefix(index + 1)))
    }
    #expect(try await pages.next() == nil)
    #expect(try await pages.next() == nil)
    let expected = decoded.flatMap(\.items)
    #expect(expected.count == count)
    var items = client(mock).items(for: request).makeAsyncIterator()
    #expect(mock.requests.count == 3)
    var actual: [MemberLegislation] = []
    for index in expected.indices {
      actual.append(try #require(try await items.next()))
      #expect(mock.requests.count == 3 + index / limit + 1)
    }
    #expect(actual == expected)
    #expect(try await items.next() == nil)
    #expect(mock.requests.map(\.request.path) == paths + paths)
  }

  private func client(_ mock: MockTransport) -> CongressDataClient {
    CongressDataClient(
      configuration: .init(apiKey: "test-key", userAgent: "CongressTests"), transport: mock)
  }

  private func invalidContinuation<Page: CongressCollection>(
    _ request: CongressRequest<Page>, fixture: Fixture, mutation: String
  ) async throws {
    // Labeled mutation of the recorded first page, never an official shape/route fixture.
    var object = try JSONDecoder().decode([String: JSONValue].self, from: fixture.data())
    var pagination = try #require(object["pagination"]?.object)
    var link = try #require(pagination["next"]?.string)
    let key =
      fixture.rawValue.contains("-cosponsored-") ? "cosponsoredLegislation" : "sponsoredLegislation"
    let limit = fixture.rawValue.contains("-cosponsored-") ? 80 : 5
    switch mutation {
    case "origin": link = link.replacingOccurrences(of: "api.congress.gov", with: "example.com")
    case "path": link = link.replacingOccurrences(of: "/v3/", with: "/v3/bill/")
    case "identity": link = link.replacingOccurrences(of: "C001136", with: "L000174")
    case "credentials": link += "&api_key=secret"
    case "duplicate": link += "&offset=\(limit)"
    case "repeated": link = link.replacingOccurrences(of: "offset=\(limit)", with: "offset=0")
    case "skipped":
      link = link.replacingOccurrences(of: "offset=\(limit)", with: "offset=\(limit + 1)")
    case "malformed": link = "not a URL"
    case "missing": pagination.removeValue(forKey: "next")
    case "limit": link = link.replacingOccurrences(of: "limit=\(limit)", with: "limit=\(limit + 1)")
    case "filter": link += "&changed=true"
    case "overrun":
      var rows = try #require(object[key]?.array)
      rows.append(rows[0])
      object[key] = .array(rows)
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
