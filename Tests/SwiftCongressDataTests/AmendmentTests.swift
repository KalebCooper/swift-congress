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
struct AmendmentTests {
  @Test("Amendment detail execution levels preserve targets without following links")
  func amendmentDetailExecutionLevelsPreserveTargetsWithoutFollowingLinks() async throws {
    let bytes = try Fixture.amendment_117_samdt_2564_detail.data()
    let mock = MockTransport(
      results: Array(repeating: .success(Response(body: bytes, status: .ok)), count: 7))
    let client = client(mock)
    let identifier = try AmendmentIdentifier(congress: 117, number: "2564", type: .senateAmendment)
    let stored = CongressRequest.amendment(identifier)
    #expect(mock.requests.isEmpty)
    let expected = try await client.amendment(identifier)
    #expect(expected.amendment.amendedAmendment?.number == "2137")
    #expect(expected.amendment.amendedBill?.number == "3684")
    #expect(mock.requests.count == 1)
    #expect(try await client.value(for: stored) == expected)
    #expect(try await client.value(for: .amendmentForArchive(identifier)) == expected)
    #expect(try await client.send(.amendment(identifier)) == expected)
    #expect(try await client.send(.amendmentForArchive(identifier)) == expected)
    #expect(
      try await client.value(for: CongressRequest(endpoint: .amendment(identifier))) == expected)
    struct Consumer: Decodable, Sendable { let amendment: Amendment }
    let endpoint = try #require(Endpoint<Consumer>(path: Endpoint.amendment(identifier).path))
    let receipt = try await client.response(for: endpoint)
    #expect(receipt.body == bytes)
    #expect(receipt.value.amendment == expected.amendment)
    #expect(mock.requests.count == 7)
    #expect(mock.requests.allSatisfy { $0.request.path == Endpoint.amendment(identifier).path })
  }

  @Test("Amendment detail keeps decoding failures typed and performs only one request")
  func amendmentDetailKeepsDecodingFailuresTypedAndPerformsOnlyOneRequest() async throws {
    // Labeled mutation of an actual detail fixture, not an additional official response.
    var fields = try JSONDecoder().decode(
      [String: JSONValue].self, from: Fixture.amendment_117_samdt_2564_detail.data())
    fields["amendment"] = .null
    let mock = MockTransport(results: [
      .success(Response(body: try JSONEncoder().encode(fields), status: .ok))
    ])
    let identifier = try AmendmentIdentifier(congress: 117, number: "2564", type: .senateAmendment)
    let failure = await #expect(throws: CongressDataError.self) {
      _ = try await client(mock).amendment(identifier)
    }
    #expect(failure != nil)
    #expect(mock.requests.count == 1)
  }

  @Test(
    "Amendment inventory execution levels cover every route scope",
    arguments: [
      Fixture.amendment_inventory_first, Fixture.amendment_117_inventory_first,
      Fixture.amendment_97_suamdt_first,
    ])
  func amendmentInventoryExecutionLevelsCoverEveryRouteScope(fixture: Fixture) async throws {
    let bytes = try fixture.data()
    let scope: AmendmentQuery.Scope
    switch fixture {
    case .amendment_inventory_first: scope = .all
    case .amendment_117_inventory_first: scope = .congress(117)
    default: scope = .type(congress: 97, type: .senateUnprintedAmendment)
    }
    let query = try AmendmentQuery(limit: 2, scope: scope)
    let mock = MockTransport(
      results: Array(repeating: .success(Response(body: bytes, status: .ok)), count: 8))
    let client = client(mock)
    let stored = CongressRequest.amendments(matching: query)
    let expected = try await client.value(for: stored)
    #expect(mock.requests.count == 1)
    #expect(try await client.value(for: .amendmentsForArchive(matching: query)) == expected)
    #expect(try await client.send(.amendments(matching: query)) == expected)
    #expect(try await client.send(.amendmentsForArchive(matching: query)) == expected)
    var pages = client.amendmentPages(matching: query).makeAsyncIterator()
    #expect(try await pages.next()?.body == bytes)
    var items = client.amendments(matching: query).makeAsyncIterator()
    #expect(try await items.next() == expected.items.first)
    var generic = client.pages(for: stored).makeAsyncIterator()
    #expect(try await generic.next()?.value == expected)
    // A consumer-defined single-response request deliberately does not traverse.
    var single = client.pages(for: CongressRequest(endpoint: .amendments(matching: query)))
      .makeAsyncIterator()
    #expect(try await single.next()?.value == expected)
    #expect(try await single.next() == nil)
    #expect(mock.requests.count == 8)
    #expect(
      mock.requests.allSatisfy { $0.request.path == Endpoint.amendments(matching: query).path })
  }

  @Test("Amendment inventory items cancel before HTTP and while buffered")
  func amendmentInventoryItemsCancelBeforeHTTPAndWhileBuffered() async throws {

    let query = try AmendmentQuery(limit: 2)
    for buffered in [false, true] {
      let mock = MockTransport(results: [
        .success(
          Response(
            body: try Fixture.amendment_inventory_first.data(),
            status: .ok
          ))
      ])
      let items = client(mock).amendments(matching: query)
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

  @Test("Amendment inventory items fetch lazily and keep traversals independent")
  func amendmentInventoryItemsFetchLazilyAndKeepTraversalsIndependent() async throws {
    let bytes = try Fixture.amendment_inventory_first.data()
    let mock = MockTransport(
      results: Array(repeating: .success(Response(body: bytes, status: .ok)), count: 4))

    let query = try AmendmentQuery(limit: 2)
    let items = client(mock).amendments(matching: query)
    var a = items.makeAsyncIterator()
    var b = items.makeAsyncIterator()
    #expect(mock.requests.isEmpty)
    #expect(try await a.next()?.number == "9")
    #expect(try await a.next()?.number == "2")
    #expect(mock.requests.count == 1)
    #expect(mock.requests.count == 1)
    #expect(try await b.next()?.number == "9")
    #expect(mock.requests.count == 2)
    var bufferedCount = 0
    for try await _ in items {
      bufferedCount += 1
      if bufferedCount == 2 { break }
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

  @Test("Amendment inventory pages remain lazy independent and cancellation aware")
  func amendmentInventoryPagesRemainLazyIndependentAndCancellationAware() async throws {
    let bytes = try Fixture.amendment_inventory_first.data()
    let mock = MockTransport(
      results: Array(repeating: .success(Response(body: bytes, status: .ok)), count: 3))

    let query = try AmendmentQuery(limit: 2)
    let pages = client(mock).amendmentPages(matching: query)
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

  @Test("Amendment inventory rejects changed scope before yielding")
  func amendmentInventoryRejectsChangedScopeBeforeYielding() async throws {
    // Changed-scope mutation of the actual SUAMDT inventory.
    var fields = try JSONDecoder().decode(
      [String: JSONValue].self, from: Fixture.amendment_97_suamdt_first.data())
    var pagination = try #require(fields["pagination"]?.object)
    let next = try #require(pagination["next"]?.string)
    pagination["next"] = .string(next.replacingOccurrences(of: "/suamdt", with: "/samdt"))
    fields["pagination"] = .object(pagination)
    let mock = MockTransport(results: [
      .success(Response(body: try JSONEncoder().encode(fields), status: .ok))
    ])
    let query = try AmendmentQuery(
      limit: 2, scope: .type(congress: 97, type: .senateUnprintedAmendment))
    var items = client(mock).amendments(matching: query).makeAsyncIterator()
    let failure = await #expect(throws: CongressDataError.self) { _ = try await items.next() }
    if case .invalidContinuation? = failure {
    } else {
      Issue.record("Expected invalid continuation")
    }
    #expect(try await items.next() == nil)
    #expect(mock.requests.count == 1)
  }

  @Test("Amendment collection traversals retain later quota failures", arguments: [false, true])
  func amendmentTraversalsRetainLaterQuotaFailures(inventory: Bool) async throws {
    let fixture: Fixture =
      inventory ? .amendment_inventory_first : .bill_117_hr_3076_amendments_first
    let bytes = try fixture.data()
    let mock = MockTransport(results: [
      .success(Response(body: bytes, status: .ok)),
      .success(Response(headers: [.retryAfter: "60"], status: .tooManyRequests)),
    ])
    let sequence: CongressPageSequence<AmendmentPage>
    if inventory {
      sequence = client(mock).amendmentPages(matching: try AmendmentQuery(limit: 2))
    } else {
      let bill = try BillIdentifier(congress: 117, number: "3076", type: .houseBill)
      sequence = client(mock).amendmentPages(for: bill, matching: try BillAmendmentQuery(limit: 16))
    }
    var pages = sequence.makeAsyncIterator()
    #expect(try await pages.next()?.body == bytes)
    #expect(mock.requests.count == 1)
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

  @Test("Bill amendment execution levels share the same initial response")
  func billAmendmentExecutionLevelsShareTheSameInitialResponse() async throws {
    let bytes = try Fixture.bill_117_hr_3076_amendments_first.data()
    let mock = MockTransport(
      results: Array(repeating: .success(Response(body: bytes, status: .ok)), count: 9))
    let client = client(mock)
    let bill = try BillIdentifier(congress: 117, number: "3076", type: .houseBill)
    let query = try BillAmendmentQuery(limit: 16)
    let stored = CongressRequest.amendments(for: bill, matching: query)
    #expect(mock.requests.isEmpty)
    let expected = try await client.value(for: stored)
    #expect(
      try await client.value(for: .amendmentsForArchive(for: bill, matching: query)) == expected)
    #expect(try await client.send(.amendmentsForArchive(for: bill, matching: query)) == expected)
    #expect(try await client.send(.amendments(for: bill.source, matching: query)) == expected)
    var pages = client.amendmentPages(for: bill, matching: query).makeAsyncIterator()
    #expect(try await pages.next()?.value == expected)
    var items = client.amendments(for: bill.source, matching: query).makeAsyncIterator()
    #expect(try await items.next() == expected.items.first)
    var genericPages = client.pages(for: stored).makeAsyncIterator()
    #expect(try await genericPages.next()?.value == expected)
    var genericItems = client.items(for: stored).makeAsyncIterator()
    #expect(try await genericItems.next() == expected.items.first)
    let receipt = try await client.response(for: Endpoint.amendments(for: bill, matching: query))
    #expect(receipt.body == bytes)
    #expect(mock.requests.count == 9)
    #expect(
      mock.requests.allSatisfy {
        $0.request.path == Endpoint.amendments(for: bill, matching: query).path
      })
  }

  @Test("Bill amendment items cancel before HTTP and while buffered")
  func billAmendmentItemsCancelBeforeHTTPAndWhileBuffered() async throws {

    let bill = try BillIdentifier(congress: 117, number: "3076", type: .houseBill)
    let query = try BillAmendmentQuery(limit: 16)
    for buffered in [false, true] {
      let mock = MockTransport(results: [
        .success(
          Response(
            body: try Fixture.bill_117_hr_3076_amendments_first.data(),
            status: .ok
          ))
      ])
      let items = client(mock).amendments(for: bill, matching: query)
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

  @Test("Bill amendment items fetch lazily and keep traversals independent")
  func billAmendmentItemsFetchLazilyAndKeepTraversalsIndependent() async throws {
    let bytes = try Fixture.bill_117_hr_3076_amendments_first.data()
    let mock = MockTransport(
      results: Array(repeating: .success(Response(body: bytes, status: .ok)), count: 4))

    let bill = try BillIdentifier(congress: 117, number: "3076", type: .houseBill)
    let query = try BillAmendmentQuery(limit: 16)
    let items = client(mock).amendments(for: bill, matching: query)
    var a = items.makeAsyncIterator()
    var b = items.makeAsyncIterator()
    #expect(mock.requests.isEmpty)
    #expect(try await a.next()?.number == "4981")
    #expect(try await a.next()?.number == "4980")
    #expect(mock.requests.count == 1)
    for _ in 2..<16 { _ = try await a.next() }
    #expect(mock.requests.count == 1)
    #expect(try await b.next()?.number == "4981")
    #expect(mock.requests.count == 2)
    var bufferedCount = 0
    for try await _ in items {
      bufferedCount += 1
      if bufferedCount == 16 { break }
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

  @Test("Bill amendment pages remain lazy independent and cancellation aware")
  func billAmendmentPagesRemainLazyIndependentAndCancellationAware() async throws {
    let bytes = try Fixture.bill_117_hr_3076_amendments_first.data()
    let mock = MockTransport(
      results: Array(repeating: .success(Response(body: bytes, status: .ok)), count: 3))

    let bill = try BillIdentifier(congress: 117, number: "3076", type: .houseBill)
    let query = try BillAmendmentQuery(limit: 16)
    let pages = client(mock).amendmentPages(for: bill, matching: query)
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
    "Bill amendment traversal rejects changed scope filters and paging",
    arguments: [
      "count", "credential", "duplicate", "filter", "limit", "malformed", "missing-next", "offset",
      "origin", "scope",
    ])
  func billAmendmentTraversalRejectsChangedScopeFiltersAndPaging(mutation: String)
    async throws
  {
    // Deliberate rejection mutations of recorded metadata.
    var fields = try JSONDecoder().decode(
      [String: JSONValue].self,
      from: Fixture.bill_117_hr_3076_amendments_first.data())
    var pagination = try #require(fields["pagination"]?.object)
    var next = try #require(pagination["next"]?.string)
    switch mutation {
    case "count": pagination["count"] = .number(1)
    case "credential": next += "&api_key=secret"
    case "duplicate": next += "&offset=16"
    case "filter": next += "&fromDateTime=2020-01-01T00:00:00Z"
    case "limit": next = next.replacingOccurrences(of: "limit=16", with: "limit=17")
    case "malformed": next = "not a URL"
    case "missing-next": break
    case "offset": next = next.replacingOccurrences(of: "offset=16", with: "offset=0")
    case "origin": next = next.replacingOccurrences(of: "api.congress.gov", with: "example.com")
    case "scope": next = next.replacingOccurrences(of: "/117/hr", with: "/118/hr")
    default: Issue.record("Unknown mutation")
    }
    pagination["next"] = mutation == "missing-next" ? nil : .string(next)
    fields["pagination"] = .object(pagination)
    let mock = MockTransport(results: [
      .success(Response(body: try JSONEncoder().encode(fields), status: .ok))
    ])

    let bill = try BillIdentifier(congress: 117, number: "3076", type: .houseBill)
    let query = try BillAmendmentQuery(limit: 16)
    var items = client(mock).amendments(for: bill, matching: query)
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
    "Bill amendment traversals reject a repeated later next link before yielding")
  func billAmendmentTraversalsRejectARepeatedLaterNextLinkBeforeYielding()
    async throws
  {
    let first = try Fixture.bill_117_hr_3076_amendments_first.data()
    var fields = try JSONDecoder().decode(
      [String: JSONValue].self,
      from: Fixture.bill_117_hr_3076_amendments_next.data())
    var pagination = try #require(fields["pagination"]?.object)
    let initial = try JSONDecoder().decode(AmendmentPage.self, from: first)
    pagination["next"] = initial.rawFields["pagination"]?.object?["next"]
    fields["pagination"] = .object(pagination)
    let mock = MockTransport(results: [
      .success(Response(body: first, status: .ok)),
      .success(Response(body: try JSONEncoder().encode(fields), status: .ok)),
    ])

    let bill = try BillIdentifier(congress: 117, number: "3076", type: .houseBill)
    let query = try BillAmendmentQuery(limit: 16)
    var pages = client(mock).amendmentPages(for: bill, matching: query)
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

  @Test("Recorded bill amendment chains follow exact links and terminate")
  func recordedBillAmendmentChainsFollowExactLinksAndTerminate() async throws {
    let bodies = try [
      Fixture.bill_117_hr_3076_amendments_first, Fixture.bill_117_hr_3076_amendments_next,
      Fixture.bill_117_hr_3076_amendments_terminal,
    ].map { try $0.data() }
    let paths = [
      "/v3/bill/117/hr/3076/amendments?format=json&limit=16&offset=0",
      "/v3/bill/117/hr/3076/amendments?offset=16&limit=16&format=json",
      "/v3/bill/117/hr/3076/amendments?offset=32&limit=16&format=json",
    ]
    let recorded = Dictionary(uniqueKeysWithValues: zip(paths, bodies))
    let mock = MockTransport()
    mock.setHandler(forPath: "/v3/bill/117/hr/3076/amendments") { request in
      guard let path = request.path, let body = recorded[path] else {
        return .success(MockTransport.Answer(Response(status: .notFound)))
      }
      return .success(MockTransport.Answer(Response(body: body, status: .ok)))
    }
    let bill = try BillIdentifier(congress: 117, number: "3076", type: .houseBill)
    let query = try BillAmendmentQuery(limit: 16)
    var pages = client(mock).amendmentPages(for: bill, matching: query).makeAsyncIterator()
    for index in bodies.indices {
      let receipt = try #require(try await pages.next())
      #expect(receipt.body == bodies[index])
      #expect(
        try receipt.value == JSONDecoder().decode(AmendmentPage.self, from: bodies[index]))
      #expect(receipt.value.pagination.count == 48)
      #expect(mock.requests.map(\.request.path) == Array(paths.prefix(index + 1)))
    }
    #expect(try await pages.next() == nil)
    var actual: [AmendmentSummary] = []
    for try await record in client(mock).amendments(for: bill, matching: query) {
      actual.append(record)
    }
    let expected = try bodies.flatMap {
      try JSONDecoder().decode(AmendmentPage.self, from: $0).items
    }
    #expect(actual == expected)
    #expect(actual.count == 48)
    #expect(mock.requests.map(\.request.path) == paths + paths)
  }

  private func client(_ mock: MockTransport) -> CongressDataClient {
    CongressDataClient(
      configuration: .init(apiKey: "test-key", userAgent: "CongressTests"), transport: mock)
  }
}

private extension CongressRequest where Response == AmendmentDetail {
  static func amendmentForArchive(_ identifier: AmendmentIdentifier) -> Self {
    .amendment(identifier)
  }
}

private extension CongressRequest where Response == AmendmentPage {
  static func amendmentsForArchive(
    for identifier: BillIdentifier, matching query: BillAmendmentQuery
  ) -> Self {
    .amendments(for: identifier, matching: query)
  }

  static func amendmentsForArchive(matching query: AmendmentQuery) -> Self {
    .amendments(matching: query)
  }
}

private extension Endpoint where Response == AmendmentDetail {
  static func amendmentForArchive(_ identifier: AmendmentIdentifier) -> Self {
    .amendment(identifier)
  }
}

private extension Endpoint where Response == AmendmentPage {
  static func amendmentsForArchive(
    for identifier: BillIdentifier, matching query: BillAmendmentQuery
  ) -> Self {
    .amendments(for: identifier, matching: query)
  }

  static func amendmentsForArchive(matching query: AmendmentQuery) -> Self {
    .amendments(matching: query)
  }
}
