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

extension CongressRequest where Response == BillCommitteePage {
  static var associationsConsumerExample: Self {
    get throws {
      try .committees(
        for: BillIdentifier(congress: 117, number: "3076", type: .houseBill),
        page: CongressQuery(limit: 2))
    }
  }
}

extension CongressRequest where Response == BillSubjectPage {
  static var associationsConsumerExample: Self {
    get throws {
      try .subjects(
        for: BillIdentifier(congress: 119, number: "5", type: .senateBill),
        matching: BillSubjectQuery(limit: 6))
    }
  }
}

extension CongressRequest where Response == RelatedBillPage {
  static var associationsConsumerExample: Self {
    get throws {
      try .relatedBills(
        for: BillIdentifier(congress: 119, number: "5", type: .senateBill),
        page: CongressQuery(limit: 2))
    }
  }
}

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct BillRelationshipsTests {
  @Test("All association execution levels retain one response")
  func allAssociationExecutionLevelsRetainOneResponse() async throws {
    do {
      let bytes = try Fixture.bill117_hr3076_committees_first.data()
      let expected = try JSONDecoder().decode(BillCommitteePage.self, from: bytes)
      let mock = MockTransport(
        results: Array(repeating: .success(Response(body: bytes, status: .ok)), count: 12))
      let client = client(mock)
      let bill = try BillIdentifier(congress: 117, number: "3076", type: .houseBill)
      let stored = CongressRequest.committees(for: bill, page: try CongressQuery(limit: 2))
      #expect(try await client.value(for: stored) == expected)
      #expect(
        try await client.value(
          for: .committees(for: bill.source, page: try CongressQuery(limit: 2))) == expected)
      #expect(
        try await client.value(for: CongressRequest<BillCommitteePage>.associationsConsumerExample)
          == expected)
      #expect(
        try await client.send(.committees(for: bill, page: try CongressQuery(limit: 2))) == expected
      )
      var pages = client.committeePages(for: bill, page: try CongressQuery(limit: 2))
        .makeAsyncIterator()
      #expect(try await pages.next()?.value == expected)
      var sourcePages = client.committeePages(for: bill.source, page: try CongressQuery(limit: 2))
        .makeAsyncIterator()
      #expect(try await sourcePages.next()?.body == bytes)
      var items = client.committees(for: bill, page: try CongressQuery(limit: 2))
        .makeAsyncIterator()
      #expect(try await items.next() == expected.items.first)
      var sourceItems = client.committees(for: bill.source, page: try CongressQuery(limit: 2))
        .makeAsyncIterator()
      #expect(try await sourceItems.next() == expected.items.first)
      var custom = client.pages(
        for: CongressRequest(endpoint: .committees(for: bill, page: try CongressQuery(limit: 2)))
      ).makeAsyncIterator()
      #expect(try await custom.next()?.value == expected)
      #expect(try await custom.next() == nil)
      struct Consumer: Decodable, Sendable { let pagination: Pagination }
      let path = Endpoint.committees(for: bill, page: try CongressQuery(limit: 2)).path
      let endpoint = try #require(Endpoint<Consumer>(path: path))
      #expect(try await client.send(endpoint).pagination == expected.pagination)
      let receipt = try await client.response(
        for: Endpoint.committees(for: bill, page: try CongressQuery(limit: 2)))
      #expect(receipt.body == bytes)
      #expect(receipt.value == expected)
      #expect(mock.requests.count == 11)
      #expect(mock.requests.allSatisfy { $0.request.path == path })
    }
    do {
      let bytes = try Fixture.bill119_s5_related_first.data()
      let expected = try JSONDecoder().decode(RelatedBillPage.self, from: bytes)
      let mock = MockTransport(
        results: Array(repeating: .success(Response(body: bytes, status: .ok)), count: 12))
      let client = client(mock)
      let bill = try BillIdentifier(congress: 119, number: "5", type: .senateBill)
      let stored = CongressRequest.relatedBills(for: bill, page: try CongressQuery(limit: 2))
      #expect(try await client.value(for: stored) == expected)
      #expect(
        try await client.value(
          for: .relatedBills(for: bill.source, page: try CongressQuery(limit: 2))) == expected)
      #expect(
        try await client.value(for: CongressRequest<RelatedBillPage>.associationsConsumerExample)
          == expected)
      #expect(
        try await client.send(.relatedBills(for: bill, page: try CongressQuery(limit: 2)))
          == expected)
      var pages = client.relatedBillPages(for: bill, page: try CongressQuery(limit: 2))
        .makeAsyncIterator()
      #expect(try await pages.next()?.value == expected)
      var sourcePages = client.relatedBillPages(for: bill.source, page: try CongressQuery(limit: 2))
        .makeAsyncIterator()
      #expect(try await sourcePages.next()?.body == bytes)
      var items = client.relatedBills(for: bill, page: try CongressQuery(limit: 2))
        .makeAsyncIterator()
      #expect(try await items.next() == expected.items.first)
      var sourceItems = client.relatedBills(for: bill.source, page: try CongressQuery(limit: 2))
        .makeAsyncIterator()
      #expect(try await sourceItems.next() == expected.items.first)
      var custom = client.pages(
        for: CongressRequest(endpoint: .relatedBills(for: bill, page: try CongressQuery(limit: 2)))
      ).makeAsyncIterator()
      #expect(try await custom.next()?.value == expected)
      #expect(try await custom.next() == nil)
      struct Consumer: Decodable, Sendable { let pagination: Pagination }
      let path = Endpoint.relatedBills(for: bill, page: try CongressQuery(limit: 2)).path
      let endpoint = try #require(Endpoint<Consumer>(path: path))
      #expect(try await client.send(endpoint).pagination == expected.pagination)
      let receipt = try await client.response(
        for: Endpoint.relatedBills(for: bill, page: try CongressQuery(limit: 2)))
      #expect(receipt.body == bytes)
      #expect(receipt.value == expected)
      #expect(mock.requests.count == 11)
      #expect(mock.requests.allSatisfy { $0.request.path == path })
    }
    do {
      let bytes = try Fixture.bill119_s5_subjects_first.data()
      let expected = try JSONDecoder().decode(BillSubjectPage.self, from: bytes)
      let mock = MockTransport(
        results: Array(repeating: .success(Response(body: bytes, status: .ok)), count: 12))
      let client = client(mock)
      let bill = try BillIdentifier(congress: 119, number: "5", type: .senateBill)
      let stored = CongressRequest.subjects(for: bill, matching: try BillSubjectQuery(limit: 6))
      #expect(try await client.value(for: stored) == expected)
      #expect(
        try await client.value(
          for: .subjects(for: bill.source, matching: try BillSubjectQuery(limit: 6))) == expected)
      #expect(
        try await client.value(for: CongressRequest<BillSubjectPage>.associationsConsumerExample)
          == expected)
      #expect(
        try await client.send(.subjects(for: bill, matching: try BillSubjectQuery(limit: 6)))
          == expected)
      var pages = client.subjectPages(for: bill, matching: try BillSubjectQuery(limit: 6))
        .makeAsyncIterator()
      #expect(try await pages.next()?.value == expected)
      var sourcePages = client.subjectPages(
        for: bill.source, matching: try BillSubjectQuery(limit: 6)
      ).makeAsyncIterator()
      #expect(try await sourcePages.next()?.body == bytes)
      var items = client.subjects(for: bill, matching: try BillSubjectQuery(limit: 6))
        .makeAsyncIterator()
      #expect(try await items.next() == expected.items.first)
      var sourceItems = client.subjects(for: bill.source, matching: try BillSubjectQuery(limit: 6))
        .makeAsyncIterator()
      #expect(try await sourceItems.next() == expected.items.first)
      var custom = client.pages(
        for: CongressRequest(
          endpoint: .subjects(for: bill, matching: try BillSubjectQuery(limit: 6)))
      ).makeAsyncIterator()
      #expect(try await custom.next()?.value == expected)
      #expect(try await custom.next() == nil)
      struct Consumer: Decodable, Sendable { let pagination: Pagination }
      let path = Endpoint.subjects(for: bill, matching: try BillSubjectQuery(limit: 6)).path
      let endpoint = try #require(Endpoint<Consumer>(path: path))
      #expect(try await client.send(endpoint).pagination == expected.pagination)
      let receipt = try await client.response(
        for: Endpoint.subjects(for: bill, matching: try BillSubjectQuery(limit: 6)))
      #expect(receipt.body == bytes)
      #expect(receipt.value == expected)
      #expect(mock.requests.count == 11)
      #expect(mock.requests.allSatisfy { $0.request.path == path })
    }
  }

  @Test("Association traversal buffers and keeps iterators independent")
  func associationTraversalBuffersAndKeepsIteratorsIndependent() async throws {
    try await buffering(
      try CongressRequest<BillCommitteePage>.associationsConsumerExample,
      fixture: .bill117_hr3076_committees_first)
    try await buffering(
      try CongressRequest<RelatedBillPage>.associationsConsumerExample,
      fixture: .bill119_s5_related_first)
    try await buffering(
      try CongressRequest<BillSubjectPage>.associationsConsumerExample,
      fixture: .bill119_s5_subjects_first)
  }

  @Test("Association traversal cancels before HTTP and while buffered")
  func associationTraversalCancelsBeforeHTTPAndWhileBuffered() async throws {
    try await cancellation(
      try CongressRequest<BillCommitteePage>.associationsConsumerExample,
      fixture: .bill117_hr3076_committees_first)
    try await cancellation(
      try CongressRequest<RelatedBillPage>.associationsConsumerExample,
      fixture: .bill119_s5_related_first)
    try await cancellation(
      try CongressRequest<BillSubjectPage>.associationsConsumerExample,
      fixture: .bill119_s5_subjects_first)
  }

  @Test("Association traversal preserves later typed failures and quota")
  func associationTraversalPreservesLaterTypedFailuresAndQuota() async throws {
    try await laterFailure(
      try CongressRequest<BillCommitteePage>.associationsConsumerExample,
      fixture: .bill117_hr3076_committees_first)
    try await laterFailure(
      try CongressRequest<RelatedBillPage>.associationsConsumerExample,
      fixture: .bill119_s5_related_first)
    try await laterFailure(
      try CongressRequest<BillSubjectPage>.associationsConsumerExample,
      fixture: .bill119_s5_subjects_first)
  }

  @Test(
    "Invalid association continuations fail before yielding",
    arguments: [
      "origin", "path", "identity", "type", "credentials", "duplicate", "repeated",
      "skipped", "malformed", "missing", "limit", "filter", "overrun", "negative",
    ])
  func invalidAssociationContinuationsFailBeforeYielding(mutation: String) async throws {
    try await invalidContinuation(
      try CongressRequest<BillCommitteePage>.associationsConsumerExample,
      fixture: .bill117_hr3076_committees_first, key: "committees", limit: 2, mutation: mutation)
    try await invalidContinuation(
      try CongressRequest<RelatedBillPage>.associationsConsumerExample,
      fixture: .bill119_s5_related_first, key: "relatedBills", limit: 2, mutation: mutation)
    try await invalidContinuation(
      try CongressRequest<BillSubjectPage>.associationsConsumerExample,
      fixture: .bill119_s5_subjects_first, key: "subjects", limit: 6, mutation: mutation)
  }

  @Test("Policy only pages remain visible and items advance on demand")
  func policyOnlyPagesRemainVisibleAndItemsAdvanceOnDemand() async throws {
    let first = try Fixture.bill119_s5_subjects_policy_first.data()
    let second = try Fixture.bill119_s5_subjects_policy_next.data()
    let mock = MockTransport(results: [
      .success(Response(body: first, status: .ok)), .success(Response(body: second, status: .ok)),
      .success(Response(body: first, status: .ok)), .success(Response(body: second, status: .ok)),
    ])
    let bill = try BillIdentifier(congress: 119, number: "5", type: .senateBill)
    let query = try BillSubjectQuery(limit: 1)
    let client = client(mock)
    var pages = client.subjectPages(for: bill, matching: query).makeAsyncIterator()
    let initial = try #require(try await pages.next())
    #expect(initial.body == first)
    #expect(initial.value.items.isEmpty)
    #expect(initial.value.policyArea?.name == "Immigration")
    #expect(mock.requests.count == 1)
    #expect(try await pages.next()?.body == second)
    #expect(mock.requests.count == 2)
    var items = client.subjects(for: bill, matching: query).makeAsyncIterator()
    #expect(mock.requests.count == 2)
    #expect(try await items.next()?.name == "Border security and unlawful immigration")
    #expect(mock.requests.count == 4)
    #expect(
      mock.requests.map(\.request.path) == [
        "/v3/bill/119/s/5/subjects?format=json&limit=1&offset=0",
        "/v3/bill/119/s/5/subjects?offset=1&limit=1&format=json",
        "/v3/bill/119/s/5/subjects?format=json&limit=1&offset=0",
        "/v3/bill/119/s/5/subjects?offset=1&limit=1&format=json",
      ])
    // Stop before the uncaptured offset2; the independent limit6 chain proves exhaustion.
  }

  @Test("Recorded association chains retain exact receipts and every item")
  func recordedAssociationChainsRetainExactReceiptsAndEveryItem() async throws {
    try await chain(
      try CongressRequest<BillCommitteePage>.associationsConsumerExample,
      fixtures: [.bill117_hr3076_committees_first, .bill117_hr3076_committees_terminal],
      itemCount: 3)
    try await chain(
      try CongressRequest<RelatedBillPage>.associationsConsumerExample,
      fixtures: [.bill119_s5_related_first, .bill119_s5_related_terminal], itemCount: 4)
    try await chain(
      try CongressRequest<BillSubjectPage>.associationsConsumerExample,
      fixtures: [.bill119_s5_subjects_first, .bill119_s5_subjects_terminal], itemCount: 11)
  }

  @Test("Subject window and sparse pages end without invented items")
  func subjectWindowAndSparsePagesEndWithoutInventedItems() async throws {
    let query = try BillSubjectQuery(
      fromDateTime: "2025-01-10T13:00:00Z", limit: 250, toDateTime: "2025-01-10T14:00:00Z")
    let bill = try BillIdentifier(congress: 119, number: "5", type: .senateBill)
    let bytes = try Fixture.bill119_s5_subjects_policy_window.data()
    let mock = MockTransport(
      results: Array(repeating: .success(Response(body: bytes, status: .ok)), count: 2))
    let client = client(mock)
    var pages = client.subjectPages(for: bill, matching: query).makeAsyncIterator()
    let receipt = try #require(try await pages.next())
    #expect(receipt.body == bytes)
    #expect(receipt.value.policyArea?.name == "Immigration")
    #expect(receipt.value.items.isEmpty)
    #expect(try await pages.next() == nil)
    var items = client.subjects(for: bill, matching: query).makeAsyncIterator()
    #expect(try await items.next() == nil)
    #expect(
      mock.requests.map(\.request.path)
        == Array(
          repeating:
            "/v3/bill/119/s/5/subjects?format=json&fromDateTime=2025-01-10T13:00:00Z&limit=250&offset=0&toDateTime=2025-01-10T14:00:00Z",
          count: 2))
    let emptyMock = MockTransport(results: [
      .success(Response(body: try Fixture.bill82_s677_subjects_sparse.data(), status: .ok))
    ])
    var empty = self.client(emptyMock).subjects(
      for: try BillIdentifier(congress: 82, number: "677", type: .senateBill),
      matching: try BillSubjectQuery()
    ).makeAsyncIterator()
    #expect(try await empty.next() == nil)
    #expect(emptyMock.requests.count == 1)
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
    _ request: CongressRequest<Page>, fixtures: [Fixture], itemCount: Int
  ) async throws where Page.Item: Equatable {
    let bodies = try fixtures.map { try $0.data() }
    let decoded = try bodies.map { try JSONDecoder().decode(Page.self, from: $0) }
    guard case .collection(let endpoint) = request.resolution else {
      Issue.record("Expected collection"); return
    }
    let nextURL = try #require(decoded[0].pagination.next)
    let url = try #require(URL(string: nextURL))
    let next = try #require(Endpoint<Page>(link: url))
    let paths = [endpoint.path, next.path]
    #expect(decoded.last?.pagination.next == nil)
    let recorded = Dictionary(uniqueKeysWithValues: zip(paths, bodies))
    let route = String(endpoint.path.split(separator: "?")[0])
    let mock = MockTransport()
    mock.setHandler(forPath: route) { request in
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
    let expected = decoded.flatMap(\.items)
    #expect(expected.count == itemCount)
    var items = client(mock).items(for: request).makeAsyncIterator()
    var actual: [Page.Item] = []
    for index in expected.indices {
      actual.append(try #require(try await items.next()))
      #expect(mock.requests.count == 2 + (index < decoded[0].items.count ? 1 : 2))
    }
    #expect(actual == expected)
    #expect(try await items.next() == nil)
    #expect(try await items.next() == nil)
    #expect(mock.requests.map(\.request.path) == paths + paths)
  }

  private func client(_ mock: MockTransport) -> CongressDataClient {
    CongressDataClient(
      configuration: .init(apiKey: "test-key", userAgent: "CongressTests"), transport: mock)
  }

  private func invalidContinuation<Page: CongressCollection>(
    _ request: CongressRequest<Page>, fixture: Fixture, key: String, limit: Int, mutation: String
  ) async throws {
    // Labeled mutation of the recorded first page, never an official shape/route fixture.
    var object = try JSONDecoder().decode([String: JSONValue].self, from: fixture.data())
    var pagination = try #require(object["pagination"]?.object)
    var link = try #require(pagination["next"]?.string)
    switch mutation {
    case "origin": link = link.replacingOccurrences(of: "api.congress.gov", with: "example.com")
    case "path": link = link.replacingOccurrences(of: "/v3/", with: "/v3/bill/")
    case "identity": link = link.replacingOccurrences(of: "/bill/", with: "/bill/118/")
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
    case "type": link = link.replacingOccurrences(of: "/bill/", with: "/amendment/")
    case "overrun":
      if key == "subjects" {
        var subjects = try #require(object[key]?.object)
        var rows = try #require(subjects["legislativeSubjects"]?.array)
        rows.append(rows[0])
        subjects["legislativeSubjects"] = .array(rows)
        object[key] = .object(subjects)
      } else {
        var rows = try #require(object[key]?.array)
        rows.append(rows[0])
        object[key] = .array(rows)
      }
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
