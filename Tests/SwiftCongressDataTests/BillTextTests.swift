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

extension CongressRequest where Response == BillTextVersionPage {
  static var modernHouseBillTextExample: Self {
    get throws {
      try .textVersions(
        for: BillIdentifier(congress: 119, number: "1", type: .houseBill),
        page: CongressQuery(limit: 2))
    }
  }
}

private let textOrigin = "https://api.congress.gov/v3/bill/119/hr/1/text"

/// A labeled provider link substituted into the recorded first text page.
struct TextLinkCase: CustomTestStringConvertible, Sendable {
  let label: String
  let pagination: [String: JSONValue]
  var testDescription: String { label }

  init(_ label: String, next link: String?) {
    self.label = label
    var pagination: [String: JSONValue] = ["count": .number(6)]
    if let link { pagination["next"] = .string(link) }
    self.pagination = pagination
  }
}

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct BillTextTests {
  private static let firstPath = "/v3/bill/119/hr/1/text?format=json&limit=2&offset=0"

  @Test(
    "A text continuation that is invalid or leaves the text route is refused before transmission",
    arguments: [
      TextLinkCase(
        "changed Congress",
        next: "https://api.congress.gov/v3/bill/118/hr/1/text?offset=2&limit=2&format=json"),
      TextLinkCase(
        "changed bill type",
        next: "https://api.congress.gov/v3/bill/119/s/1/text?offset=2&limit=2&format=json"),
      TextLinkCase(
        "changed bill number",
        next: "https://api.congress.gov/v3/bill/119/hr/2/text?offset=2&limit=2&format=json"),
      TextLinkCase(
        "bill route without text",
        next: "https://api.congress.gov/v3/bill/119/hr/1?offset=2&limit=2&format=json"),
      TextLinkCase("changed page size", next: textOrigin + "?offset=2&limit=3&format=json"),
      TextLinkCase(
        "duplicate query parameter", next: textOrigin + "?offset=2&offset=4&limit=2&format=json"),
      TextLinkCase(
        "dot segment",
        next: "https://api.congress.gov/v3/bill/119/hr/2/../1/text?offset=2&limit=2&format=json"),
      TextLinkCase(
        "foreign origin",
        next: "https://example.com/v3/bill/119/hr/1/text?offset=2&limit=2&format=json"),
      TextLinkCase(
        "credential in authority",
        next:
          "https://user:secret@api.congress.gov/v3/bill/119/hr/1/text?offset=2&limit=2&format=json"),
      TextLinkCase(
        "credential in query", next: textOrigin + "?offset=2&limit=2&format=json&api_key=secret"),
      TextLinkCase(
        "format link on the asset host",
        next: "https://www.congress.gov/119/bills/hr1/BILLS-119hr1enr.htm"),
      TextLinkCase("missing link with records remaining", next: nil),
      TextLinkCase("repeated offset", next: textOrigin + "?offset=0&limit=2&format=json"),
      TextLinkCase(
        "offset advanced by the returned count", next: textOrigin + "?offset=3&limit=2&format=json"),
      TextLinkCase(
        "malformed link", next: "api.congress.gov/v3/bill/119/hr/1/text?offset=2&limit=2"),
    ])
  func aTextContinuationThatIsInvalidOrLeavesTheTextRouteIsRefusedBeforeTransmission(
    link: TextLinkCase
  ) async throws {
    var object = try JSONDecoder().decode(
      [String: JSONValue].self, from: Fixture.bill119_text_first.data())
    object["pagination"] = .object(link.pagination)
    let mock = MockTransport(results: [
      .success(Response(body: try JSONEncoder().encode(object), status: .ok))
    ])
    var pages = try client(mock).textVersionPages(for: modernBill(), page: CongressQuery(limit: 2))
      .makeAsyncIterator()
    let failure = await #expect(throws: CongressDataError.self) { _ = try await pages.next() }
    if case .invalidContinuation? = failure {
    } else {
      Issue.record("Expected an invalid continuation")
    }
    #expect(try await pages.next() == nil)
    #expect(mock.requests.map(\.request.path) == [Self.firstPath])
    expectTextRequests(mock)
  }

  @Test("A terminal text page ends the traversal after one request")
  func aTerminalTextPageEndsTheTraversalAfterOneRequest() async throws {
    let bytes = try Fixture.bill119_text_terminal.data()
    let mock = MockTransport(
      results: Array(repeating: .success(Response(body: bytes, status: .ok)), count: 2))
    let identifier = try modernBill()
    let query = try CongressQuery(limit: 2, offset: 5)
    var pages = client(mock).textVersionPages(for: identifier, page: query).makeAsyncIterator()
    let page = try #require(try await pages.next())
    #expect(page.body == bytes)
    #expect(page.value.textVersions.map(\.type) == ["Public Law"])
    #expect(try await pages.next() == nil)
    var versions = client(mock).textVersions(for: identifier, page: query).makeAsyncIterator()
    #expect(try await versions.next()?.date == "2025-07-05T03:59:59Z")
    #expect(try await versions.next() == nil)
    #expect(
      mock.requests.map(\.request.path)
        == Array(repeating: "/v3/bill/119/hr/1/text?format=json&limit=2&offset=5", count: 2))
    expectTextRequests(mock)
  }

  @Test("An empty text inventory is empty only after a successful response")
  func anEmptyTextInventoryIsEmptyOnlyAfterASuccessfulResponse() async throws {
    // Labeled mutation: the recorded first page with no versions and a zero count.
    var object = try JSONDecoder().decode(
      [String: JSONValue].self, from: Fixture.bill119_text_first.data())
    object["textVersions"] = .array([])
    object["pagination"] = .object(["count": .number(0)])
    let mock = MockTransport(results: [
      .success(Response(body: try JSONEncoder().encode(object), status: .ok)),
      .success(Response(status: .notFound)),
    ])
    let versions = try client(mock).textVersions(for: modernBill(), page: CongressQuery(limit: 2))
    var empty = versions.makeAsyncIterator()
    #expect(try await empty.next() == nil)
    #expect(mock.requests.count == 1)
    var missing = versions.makeAsyncIterator()
    let failure = await #expect(throws: CongressDataError.self) { _ = try await missing.next() }
    if case .transport(.httpStatus(_, let code, _))? = failure {
      #expect(code == 404)
    } else {
      Issue.record("Expected a 404 response")
    }
    #expect(try await missing.next() == nil)
    #expect(mock.requests.map(\.request.path) == [Self.firstPath, Self.firstPath])
    expectTextRequests(mock)
  }

  @Test("Cancellation before a text traversal starts sends no request")
  func cancellationBeforeATextTraversalStartsSendsNoRequest() async throws {
    let mock = MockTransport()
    let resume = Gate()
    let versions = try client(mock).textVersions(
      for: modernBill(), page: CongressQuery(limit: 2))
    let task = Task {
      await resume.wait()
      var iterator = versions.makeAsyncIterator()
      do {
        _ = try await iterator.next(); Issue.record("Expected cancellation")
      } catch CongressDataError.transport(.cancelled) {}
      #expect(try await iterator.next() == nil)
    }
    task.cancel()
    await resume.open()
    try await task.value
    #expect(mock.requests.isEmpty)
  }

  @Test("Cancellation while text versions are buffered returns no additional version")
  func cancellationWhileTextVersionsAreBufferedReturnsNoAdditionalVersion() async throws {
    let mock = MockTransport(results: [
      .success(Response(body: try Fixture.bill119_text_first.data(), status: .ok))
    ])
    let versions = try client(mock).textVersions(
      for: modernBill(), page: CongressQuery(limit: 2))
    let ready = Gate()
    let resume = Gate()
    let task = Task {
      var iterator = versions.makeAsyncIterator()
      #expect(try await iterator.next()?.type == "Enrolled Bill")
      await ready.open()
      await resume.wait()
      do {
        _ = try await iterator.next(); Issue.record("Expected cancellation")
      } catch CongressDataError.transport(.cancelled) {}
      #expect(try await iterator.next() == nil)
    }
    await ready.wait()
    task.cancel()
    await resume.open()
    try await task.value
    #expect(mock.requests.count == 1)
    expectTextRequests(mock)
  }

  @Test("Every text execution level returns the same provider page for both identifier forms")
  func everyTextExecutionLevelReturnsTheSameProviderPageForBothIdentifierForms() async throws {
    let bytes = try Fixture.bill119_text_first.data()
    let mock = MockTransport(
      results: Array(repeating: .success(Response(body: bytes, status: .ok)), count: 9))
    let client = client(mock)
    let query = try CongressQuery(limit: 2)
    let numbered = try BillIdentifier(congress: 119, number: "1", type: .houseBill)
    let source = numbered.source

    var sourcePages = client.textVersionPages(for: source, page: query).makeAsyncIterator()
    let page = try #require(try await sourcePages.next())
    #expect(page.body == bytes)
    #expect(page.status == 200)
    #expect(page.value.textVersions.count == 3)
    #expect(try await client.value(for: .textVersions(for: source, page: query)) == page.value)
    #expect(try await client.send(.textVersions(for: source, page: query)) == page.value)
    let sourceReceipt = try await client.response(for: .textVersions(for: source, page: query))
    #expect(sourceReceipt.body == bytes)
    #expect(sourceReceipt.status == 200)
    #expect(sourceReceipt.value == page.value)

    var numberedPages = client.textVersionPages(for: numbered, page: query).makeAsyncIterator()
    #expect(try await numberedPages.next()?.value == page.value)
    let stored = CongressRequest.textVersions(for: numbered, page: query)
    #expect(try await client.value(for: stored) == page.value)
    #expect(try await client.value(for: .modernHouseBillTextExample) == page.value)
    #expect(try await client.send(.textVersions(for: numbered, page: query)) == page.value)
    let numberedReceipt = try await client.response(for: .textVersions(for: numbered, page: query))
    #expect(numberedReceipt.body == bytes)
    #expect(numberedReceipt.value == page.value)

    #expect(mock.requests.count == 9)
    for call in mock.requests {
      #expect(call.request.path == Self.firstPath)
      #expect(call.request.headerFields[HTTPField.Name("X-Api-Key")!] == "test-key")
      #expect(call.request.headerFields[.userAgent] == "CongressTests")
    }
    expectTextRequests(mock)
  }

  @Test("Later text page failures end the iterator with typed errors and quota headers")
  func laterTextPageFailuresEndTheIteratorWithTypedErrorsAndQuotaHeaders() async throws {
    let first = try Fixture.bill119_text_first.data()
    let mock = MockTransport(results: [
      .success(Response(body: first, status: .ok)),
      .success(Response(headers: [.retryAfter: "60"], status: .tooManyRequests)),
      .success(Response(body: first, status: .ok)),
      .success(Response(body: Data("{}".utf8), status: .ok)),
    ])
    let pages = try client(mock).textVersionPages(
      for: modernBill(), page: CongressQuery(limit: 2))
    var limited = pages.makeAsyncIterator()
    _ = try await limited.next()
    let quota = await #expect(throws: CongressDataError.self) { _ = try await limited.next() }
    if case .transport(.httpStatus(_, let code, let headers))? = quota {
      #expect(code == 429)
      #expect(headers[.retryAfter] == "60")
    } else {
      Issue.record("Expected a 429 response")
    }
    #expect(try await limited.next() == nil)
    #expect(mock.requests.count == 2)
    var malformed = pages.makeAsyncIterator()
    _ = try await malformed.next()
    let decoding = await #expect(throws: CongressDataError.self) { _ = try await malformed.next() }
    if case .decoding? = decoding {} else { Issue.record("Expected a decoding failure") }
    #expect(try await malformed.next() == nil)
    let second = "/v3/bill/119/hr/1/text?offset=2&limit=2&format=json"
    #expect(
      mock.requests.map(\.request.path) == [Self.firstPath, second, Self.firstPath, second])
    expectTextRequests(mock)
  }

  @Test("Text construction sends nothing and the first request fetches one page")
  func textConstructionSendsNothingAndTheFirstRequestFetchesOnePage() async throws {
    let mock = MockTransport(results: [
      .success(Response(body: try Fixture.bill119_text_first.data(), status: .ok)),
      .success(Response(body: try Fixture.bill119_text_first.data(), status: .ok)),
    ])
    let client = client(mock)
    let query = try CongressQuery(limit: 2)
    let numbered = try BillIdentifier(congress: 119, number: "1", type: .houseBill)
    _ = client.textVersions(for: numbered.source, page: query).makeAsyncIterator()
    _ = client.textVersions(for: numbered, page: query).makeAsyncIterator()
    _ = client.items(for: .textVersions(for: numbered, page: query)).makeAsyncIterator()
    var sourcePages = client.textVersionPages(for: numbered.source, page: query)
      .makeAsyncIterator()
    var numberedPages = client.textVersionPages(for: numbered, page: query).makeAsyncIterator()
    #expect(mock.requests.isEmpty)
    #expect(try await sourcePages.next()?.value.textVersions.count == 3)
    #expect(mock.requests.count == 1)
    #expect(try await numberedPages.next()?.value.textVersions.count == 3)
    #expect(Endpoint.textVersions(for: numbered, page: query).path == Self.firstPath)
    #expect(mock.requests.map(\.request.path) == [Self.firstPath, Self.firstPath])
    expectTextRequests(mock)
  }

  @Test("Text pages follow every recorded provider link to the end and yield repeats again")
  func textPagesFollowEveryRecordedProviderLinkToTheEndAndYieldRepeatsAgain() async throws {
    let first = try Fixture.bill119_text_first.data()
    let second = try Fixture.bill119_text_next.data()
    let offset4 = try Fixture.bill119_text_offset4.data()
    let offset2Path = "/v3/bill/119/hr/1/text?offset=2&limit=2&format=json"
    let offset4Path = "/v3/bill/119/hr/1/text?offset=4&limit=2&format=json"
    // Each recorded page answers only its exact recorded request target; the page at offset 5
    // answers only if a provider link names that target.
    let recorded = [
      Self.firstPath: first, offset2Path: second, offset4Path: offset4,
      "/v3/bill/119/hr/1/text?offset=5&limit=2&format=json":
        try Fixture.bill119_text_terminal.data(),
    ]
    let mock = MockTransport()
    mock.setHandler(forPath: "/v3/bill/119/hr/1/text") { request in
      guard let path = request.path, let body = recorded[path] else {
        return .success(MockTransport.Answer(Response(status: .notFound)))
      }
      return .success(MockTransport.Answer(Response(body: body, status: .ok)))
    }
    let identifier = try modernBill()
    let query = try CongressQuery(limit: 2)
    var pages = client(mock).textVersionPages(for: identifier, page: query).makeAsyncIterator()
    let page = try #require(try await pages.next())
    #expect(page.body == first)
    #expect(page.value.pagination.next == textOrigin + "?offset=2&limit=2&format=json")
    let next = try #require(try await pages.next())
    #expect(next.body == second)
    #expect(next.value.pagination.next == textOrigin + "?offset=4&limit=2&format=json")
    let last = try #require(try await pages.next())
    #expect(last.body == offset4)
    #expect(last.value.pagination.count == 6)
    #expect(last.value.pagination.next == nil)
    #expect(try await pages.next() == nil)

    var versions = client(mock).textVersions(for: identifier, page: query).makeAsyncIterator()
    var yielded: [BillTextVersion] = []
    for _ in 0..<8 { yielded.append(try #require(try await versions.next())) }
    #expect(try await versions.next() == nil)
    #expect(
      yielded.map(\.type) == [
        "Enrolled Bill", "Engrossed Amendment Senate", "Public Law", "Placed on Calendar Senate",
        "Engrossed in House", "Public Law", "Reported in House", "Public Law",
      ])
    #expect(
      yielded.map(\.date) == [
        nil, "2025-07-01T04:00:00Z", "2025-07-05T03:59:59Z", "2025-06-28T04:00:00Z",
        "2025-05-22T04:00:00Z", "2025-07-05T03:59:59Z", "2025-05-20T04:00:00Z",
        "2025-07-05T03:59:59Z",
      ])
    #expect(yielded[2] == yielded[5])
    #expect(yielded[5] == yielded[7])

    let traversal = [Self.firstPath, offset2Path, offset4Path]
    #expect(mock.requests.map(\.request.path) == traversal + traversal)
    expectTextRequests(mock)
  }

  @Test("Text items drain the current page and iterators start independently")
  func textItemsDrainTheCurrentPageAndIteratorsStartIndependently() async throws {
    let first = try Fixture.bill119_text_first.data()
    let mock = MockTransport(
      results: Array(repeating: .success(Response(body: first, status: .ok)), count: 3))
    let versions = try client(mock).textVersions(
      for: modernBill(), page: CongressQuery(limit: 2))
    var types: [String?] = []
    for try await version in versions {
      types.append(version.type)
      if types.count == 3 { break }
    }
    #expect(types == ["Enrolled Bill", "Engrossed Amendment Senate", "Public Law"])
    #expect(mock.requests.count == 1)
    var a = versions.makeAsyncIterator()
    var b = versions.makeAsyncIterator()
    #expect(try await a.next()?.type == "Enrolled Bill")
    #expect(mock.requests.count == 2)
    #expect(try await b.next()?.type == "Enrolled Bill")
    #expect(try await a.next()?.type == "Engrossed Amendment Senate")
    #expect(mock.requests.count == 3)
    #expect(mock.requests.allSatisfy { $0.request.path == Self.firstPath })
    expectTextRequests(mock)
  }

  @Test("Text value, send, and custom requests retrieve only one response")
  func textValueSendAndCustomRequestsRetrieveOnlyOneResponse() async throws {
    let first = try Fixture.bill119_text_first.data()
    let mock = MockTransport(
      results: Array(repeating: .success(Response(body: first, status: .ok)), count: 3))
    let client = client(mock)
    let identifier = try modernBill()
    let query = try CongressQuery(limit: 2)
    let value = try await client.value(for: .textVersions(for: identifier, page: query))
    #expect(value.textVersions.count == 3)
    #expect(try await client.send(.textVersions(for: identifier, page: query)) == value)
    var custom = client.pages(
      for: CongressRequest(endpoint: .textVersions(for: identifier, page: query))
    ).makeAsyncIterator()
    #expect(try await custom.next()?.value == value)
    #expect(try await custom.next() == nil)
    #expect(mock.requests.count == 3)
    #expect(mock.requests.allSatisfy { $0.request.path == Self.firstPath })
    expectTextRequests(mock)
  }

  private func client(_ transport: MockTransport) -> CongressDataClient {
    CongressDataClient(
      configuration: .init(apiKey: "test-key", userAgent: "CongressTests"), transport: transport)
  }

  /// Every request goes to the Congress.gov API text route, never to a supplied format link.
  private func expectTextRequests(_ mock: MockTransport) {
    for call in mock.requests {
      #expect(call.request.scheme == "https")
      #expect(call.request.authority == "api.congress.gov")
      #expect(call.request.path?.hasPrefix("/v3/bill/119/hr/1/text?") == true)
    }
  }

  private func modernBill() throws -> BillSourceIdentifier {
    try BillSourceIdentifier(congress: 119, number: "1", type: .houseBill)
  }
}
