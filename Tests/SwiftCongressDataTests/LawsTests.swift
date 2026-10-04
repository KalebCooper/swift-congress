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

extension CongressRequest where Response == BillPage {
  static var lawsConsumerExample: Self {
    get throws { try .laws(matching: LawQuery(congress: 117, limit: 1, type: .private)) }
  }
}

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct LawsTests {
  @Test("All law execution levels retain the originating bill response")
  func allLawExecutionLevelsRetainTheOriginatingBillResponse() async throws {
    let bytes = try Fixture.law117_private_first.data()
    let mock = MockTransport(
      results: Array(repeating: .success(Response(body: bytes, status: .ok)), count: 8))
    let client = client(mock)
    let query = try LawQuery(congress: 117, limit: 1, type: .private)
    let stored = CongressRequest.laws(matching: query)
    let expected = try await client.value(for: stored)
    #expect(try await client.value(for: .lawsConsumerExample) == expected)
    #expect(try await client.send(.laws(matching: query)) == expected)
    var pages = client.lawPages(matching: query).makeAsyncIterator()
    #expect(try await pages.next()?.value == expected)
    var items = client.laws(matching: query).makeAsyncIterator()
    #expect(try await items.next() == expected.items.first)
    var custom = client.pages(for: CongressRequest(endpoint: .laws(matching: query)))
      .makeAsyncIterator()
    #expect(try await custom.next()?.value == expected)
    #expect(try await custom.next() == nil)
    struct Consumer: Decodable, Sendable { let pagination: Pagination }
    let endpoint = try #require(Endpoint<Consumer>(path: Endpoint.laws(matching: query).path))
    #expect(try await client.send(endpoint).pagination.count == 3)
    let receipt = try await client.response(for: Endpoint.laws(matching: query))
    #expect(receipt.body == bytes)
    #expect(receipt.value == expected)
    #expect(mock.requests.count == 8)
  }

  @Test(
    "Invalid law continuations fail before any bill is yielded",
    arguments: [
      "origin", "path", "identity", "type", "credentials", "duplicate", "repeated", "skipped",
      "malformed", "missing", "limit", "filter", "overrun", "negative",
    ])
  func invalidLawContinuationsFailBeforeAnyBillIsYielded(mutation: String) async throws {
    try await invalidContinuation(
      try .lawsConsumerExample, fixture: .law117_private_first, mutation: mutation)
  }

  @Test("Law detail uses the law number without fetching its originating bill")
  func lawDetailUsesTheLawNumberWithoutFetchingItsOriginatingBill() async throws {
    for (fixture, congress, type, number, billType) in [
      (Fixture.law119_public1, 119, LawType.public, "5", "S"),
      (.law117_private1, 117, .private, "681", "HR"),
      (.law93_public1, 93, .public, "1", "HJRES"),
    ] {
      let bytes = try fixture.data()
      let expected = try JSONDecoder().decode(BillDetail.self, from: bytes)
      let mock = MockTransport(
        results: Array(repeating: .success(Response(body: bytes, status: .ok)), count: 4))
      let client = client(mock)
      let identifier = try LawIdentifier(congress: congress, number: "1", type: type)
      #expect(try await client.law(identifier) == expected)
      #expect(try await client.value(for: .law(identifier)) == expected)
      #expect(try await client.send(.law(identifier)) == expected)
      let receipt = try await client.response(for: Endpoint.law(identifier))
      #expect(receipt.body == bytes)
      #expect(receipt.value.bill.number == number)
      #expect(receipt.value.bill.type.rawValue == billType)
      #expect(receipt.value.bill.laws?.first?.number == "\(congress)-1")
      #expect(mock.requests.count == 4)
      #expect(
        mock.requests.allSatisfy {
          $0.request.path == "/v3/law/\(congress)/\(type.rawValue)/1?format=json"
        })
    }
  }

  @Test("Law traversal buffers lazily and keeps iterators independent")
  func lawTraversalBuffersLazilyAndKeepsIteratorsIndependent() async throws {
    let request = try CongressRequest.laws(matching: LawQuery(congress: 119, limit: 2))
    try await buffering(request, fixture: .law119_inventory)
  }

  @Test("Law traversal cancels before HTTP and while buffered")
  func lawTraversalCancelsBeforeHTTPAndWhileBuffered() async throws {
    let request = try CongressRequest.laws(matching: LawQuery(congress: 119, limit: 2))
    try await cancellation(request, fixture: .law119_inventory)
  }

  @Test("Law traversal preserves later typed failures and quota headers")
  func lawTraversalPreservesLaterTypedFailuresAndQuotaHeaders() async throws {
    try await laterFailure(try .lawsConsumerExample, fixture: .law117_private_first)
  }

  @Test("Public and combined law inventories use their captured routes")
  func publicAndCombinedLawInventoriesUseTheirCapturedRoutes() async throws {
    for (fixture, type) in [
      (Fixture.law119_inventory, Optional<LawType>.none),
      (.law119_public_inventory, .some(.public)),
    ] {
      let bytes = try fixture.data()
      let mock = MockTransport(results: [.success(Response(body: bytes, status: .ok))])
      let query = try LawQuery(congress: 119, limit: 2, type: type)
      var pages = client(mock).lawPages(matching: query).makeAsyncIterator()
      #expect(try await pages.next()?.body == bytes)
      #expect(mock.requests.map(\.request.path) == [Endpoint.laws(matching: query).path])
    }
  }

  @Test("Recorded private law chain preserves every bill page and source receipt")
  func recordedPrivateLawChainPreservesEveryBillPageAndSourceReceipt() async throws {
    try await chain(
      try .lawsConsumerExample, count: 3,
      fixtures: [.law117_private_first, .law117_private_next, .law117_private_terminal],
      limit: 1)
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
    _ request: CongressRequest<Page>, count: Int, fixtures: [Fixture], limit: Int
  ) async throws where Page.Item == Bill {
    let bodies = try fixtures.map { try $0.data() }
    let decoded = try bodies.map { try JSONDecoder().decode(Page.self, from: $0) }
    let paths = [
      "/v3/law/117/priv?format=json&limit=\(limit)&offset=0",
      "/v3/law/117/priv?offset=\(limit)&limit=\(limit)&format=json",
      "/v3/law/117/priv?offset=\(limit * 2)&limit=\(limit)&format=json",
    ]
    #expect(decoded.map(\.pagination.count) == [3, 3, 3])
    #expect(decoded.last?.pagination.next == nil)
    let recorded = Dictionary(uniqueKeysWithValues: zip(paths, bodies))
    let mock = MockTransport()
    // Exact request targets answer only with the original captured bytes.
    mock.setHandler(forPath: "/v3/law/117/priv") { request in
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
    var actual: [Bill] = []
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
    let key = "bills"
    let limit = 1
    switch mutation {
    case "origin": link = link.replacingOccurrences(of: "api.congress.gov", with: "example.com")
    case "path": link = link.replacingOccurrences(of: "/v3/", with: "/v3/bill/")
    case "identity": link = link.replacingOccurrences(of: "/117/", with: "/118/")
    case "credentials": link += "&api_key=secret"
    case "duplicate": link += "&offset=\(limit)"
    case "repeated": link = link.replacingOccurrences(of: "offset=\(limit)", with: "offset=0")
    case "skipped":
      link = link.replacingOccurrences(of: "offset=\(limit)", with: "offset=\(limit + 1)")
    case "malformed": link = "not a URL"
    case "missing": pagination.removeValue(forKey: "next")
    case "limit": link = link.replacingOccurrences(of: "limit=\(limit)", with: "limit=\(limit + 1)")
    case "filter": link += "&changed=true"
    case "negative": pagination["count"] = .number(-1)
    case "type": link = link.replacingOccurrences(of: "/priv?", with: "/pub?")
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
