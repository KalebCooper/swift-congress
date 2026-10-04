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

extension CongressRequest where Response == BillCosponsorPage {
  static var cosponsorsConsumerExample: Self {
    get throws {
      try .cosponsors(
        for: BillSourceIdentifier(congress: 117, number: "3580", type: .senateBill),
        matching: BillCosponsorQuery(limit: 15))
    }
  }
}

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct BillCosponsorTests {
  @Test("All cosponsor execution levels retain the original response")
  func allCosponsorExecutionLevelsRetainTheOriginalResponse() async throws {
    let bytes = try Fixture.bill117_s3580_cosponsors_first.data()
    let mock = MockTransport(
      results: Array(repeating: .success(Response(body: bytes, status: .ok)), count: 8))
    let client = client(mock)
    let bill = try BillIdentifier(congress: 117, number: "3580", type: .senateBill)
    let query = try BillCosponsorQuery(limit: 15)
    let stored = CongressRequest.cosponsors(for: bill, matching: query)
    let expected = try await client.value(for: stored)
    #expect(try await client.value(for: .cosponsorsConsumerExample) == expected)
    #expect(try await client.value(for: .cosponsors(for: bill.source, matching: query)) == expected)
    #expect(try await client.send(.cosponsors(for: bill, matching: query)) == expected)
    var pages = client.cosponsorPages(for: bill, matching: query).makeAsyncIterator()
    #expect(try await pages.next()?.value == expected)
    var items = client.cosponsors(for: bill, matching: query).makeAsyncIterator()
    #expect(try await items.next() == expected.items.first)
    var custom = client.pages(
      for: CongressRequest(endpoint: .cosponsors(for: bill, matching: query))
    )
    .makeAsyncIterator()
    #expect(try await custom.next()?.value == expected)
    #expect(try await custom.next() == nil)
    struct Consumer: Decodable, Sendable { let pagination: Pagination }
    let endpoint = try #require(
      Endpoint<Consumer>(path: Endpoint.cosponsors(for: bill, matching: query).path))
    #expect(try await client.send(endpoint).pagination.count == 30)
    #expect(mock.requests.count == 8)
  }

  @Test("Cosponsor traversal buffers lazily and keeps iterators independent")
  func cosponsorTraversalBuffersLazilyAndKeepsIteratorsIndependent() async throws {
    try await buffering(try .cosponsorsConsumerExample, fixture: .bill117_s3580_cosponsors_first)
  }

  @Test("Cosponsor traversal cancels before HTTP and while buffered")
  func cosponsorTraversalCancelsBeforeHTTPAndWhileBuffered() async throws {
    try await cancellation(try .cosponsorsConsumerExample, fixture: .bill117_s3580_cosponsors_first)
  }

  @Test("Cosponsor traversal preserves later typed failures and quota headers")
  func cosponsorTraversalPreservesLaterTypedFailuresAndQuotaHeaders() async throws {
    try await laterFailure(try .cosponsorsConsumerExample, fixture: .bill117_s3580_cosponsors_first)
  }

  @Test("Empty recorded cosponsors yield one receipt and no items")
  func emptyRecordedCosponsorsYieldOneReceiptAndNoItems() async throws {
    let bytes = try Fixture.bill119_hr1_cosponsors_current.data()
    let mock = MockTransport(
      results: Array(repeating: .success(Response(body: bytes, status: .ok)), count: 2))
    let bill = try BillSourceIdentifier(congress: 119, number: "1", type: .houseBill)
    let query = try BillCosponsorQuery(limit: 2)
    var pages = client(mock).cosponsorPages(for: bill, matching: query).makeAsyncIterator()
    let receipt = try #require(try await pages.next())
    #expect(receipt.body == bytes)
    #expect(receipt.value.items.isEmpty)
    #expect(receipt.value.pagination.count == 0)
    #expect(receipt.value.countIncludingWithdrawnCosponsors == 0)
    #expect(try await pages.next() == nil)
    var items = client(mock).cosponsors(for: bill, matching: query).makeAsyncIterator()
    #expect(try await items.next() == nil)
    #expect(mock.requests.count == 2)
  }

  @Test(
    "Invalid cosponsor continuations fail before any record is yielded",
    arguments: [
      "origin", "path", "identity", "credentials", "duplicate", "repeated", "skipped",
      "malformed", "missing", "limit", "filter", "overrun", "negative", "below-active",
      "negative-active",
    ])
  func invalidCosponsorContinuationsFailBeforeAnyRecordIsYielded(mutation: String) async throws {
    try await invalidContinuation(
      try .cosponsorsConsumerExample, fixture: .bill117_s3580_cosponsors_first, mutation: mutation)
  }

  @Test("Recorded cosponsor chain preserves every row page and source receipt")
  func recordedCosponsorChainPreservesEveryRowPageAndSourceReceipt() async throws {
    try await chain(
      try .cosponsorsConsumerExample, count: 31,
      fixtures: [
        .bill117_s3580_cosponsors_first, .bill117_s3580_cosponsors_next,
        .bill117_s3580_cosponsors_terminal,
      ], limit: 15, route: "cosponsors")
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
  ) async throws where Page.Item == BillCosponsor {
    let bodies = try fixtures.map { try $0.data() }
    let decoded = try bodies.map { try JSONDecoder().decode(Page.self, from: $0) }
    let paths = [
      "/v3/bill/117/s/3580/\(route)?format=json&limit=\(limit)&offset=0",
      "/v3/bill/117/s/3580/\(route)?offset=\(limit)&limit=\(limit)&format=json",
      "/v3/bill/117/s/3580/\(route)?offset=\(limit * 2)&limit=\(limit)&format=json",
    ]
    #expect(decoded.map(\.pagination.count) == [30, 30, 30])
    #expect(decoded.last?.pagination.next == nil)
    let recorded = Dictionary(uniqueKeysWithValues: zip(paths, bodies))
    let mock = MockTransport()
    // Exact request targets answer only with the original captured bytes.
    mock.setHandler(forPath: "/v3/bill/117/s/3580/\(route)") { request in
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
    var actual: [BillCosponsor] = []
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
    let key = "cosponsors"
    let limit = 15
    switch mutation {
    case "origin": link = link.replacingOccurrences(of: "api.congress.gov", with: "example.com")
    case "path": link = link.replacingOccurrences(of: "/v3/", with: "/v3/bill/")
    case "identity": link = link.replacingOccurrences(of: "3580", with: "3581")
    case "credentials": link += "&api_key=secret"
    case "duplicate": link += "&offset=\(limit)"
    case "repeated": link = link.replacingOccurrences(of: "offset=\(limit)", with: "offset=0")
    case "skipped":
      link = link.replacingOccurrences(of: "offset=\(limit)", with: "offset=\(limit + 1)")
    case "malformed": link = "not a URL"
    case "missing": pagination.removeValue(forKey: "next")
    case "limit": link = link.replacingOccurrences(of: "limit=\(limit)", with: "limit=\(limit + 1)")
    case "filter": link += "&changed=true"
    case "negative": pagination["countIncludingWithdrawnCosponsors"] = .number(-1)
    case "below-active": pagination["countIncludingWithdrawnCosponsors"] = .number(29)
    case "negative-active": pagination["count"] = .number(-1)
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
