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

extension CongressRequest where Response == BillDetail {
  static var historicalExample: Self {
    .bill(try! BillSourceIdentifier(congress: 6, number: "1", type: .houseBill))
  }
}

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct CongressDataTests {
  @Test("A later page failure terminates its iterator and preserves quota headers")
  func aLaterPageFailureTerminatesItsIteratorAndPreservesQuotaHeaders() async throws {
    let mock = MockTransport(results: [
      .success(Response(body: try Fixture.bills6_first.data(), status: .ok)),
      .success(Response(headers: [.retryAfter: "60"], status: .tooManyRequests)),
    ])
    var iterator = client(mock).billPages(matching: try BillQuery(congress: 6, limit: 2))
      .makeAsyncIterator()
    _ = try await iterator.next()
    do {
      _ = try await iterator.next(); Issue.record("Expected a quota failure")
    } catch CongressDataError.transport(.httpStatus(_, let code, let headers)) {
      #expect(code == 429); #expect(headers[.retryAfter] == "60")
    }
    #expect(try await iterator.next() == nil)
    #expect(mock.requests.count == 2)
  }

  @Test("Cancellation before execution sends no request")
  func cancellationBeforeExecutionSendsNoRequest() async throws {
    let mock = MockTransport()
    let resume = Gate()
    let task = Task {
      await resume.wait()
      do {
        _ = try await client(mock).value(for: .historicalExample);
        Issue.record("Expected cancellation")
      } catch CongressDataError.transport(.cancelled) {}
    }
    task.cancel()
    await resume.open()
    try await task.value
    #expect(mock.requests.isEmpty)
  }

  @Test("Cancellation while items are buffered returns no additional item")
  func cancellationWhileItemsAreBufferedReturnsNoAdditionalItem() async throws {
    let mock = MockTransport(results: [
      .success(Response(body: try Fixture.bills6_first.data(), status: .ok))
    ])
    let ready = Gate()
    let resume = Gate()
    let task = Task {
      var iterator = client(mock).bills(matching: try BillQuery(congress: 6, limit: 2))
        .makeAsyncIterator()
      _ = try await iterator.next()
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
  }

  @Test("Consumer-defined responses use the same executor")
  func consumerDefinedResponsesUseTheSameExecutor() async throws {
    struct Custom: Decodable, Sendable { let request: JSONValue }
    let mock = MockTransport(results: [
      .success(Response(body: try Fixture.bill6.data(), status: .ok))
    ])
    let endpoint = try #require(Endpoint<Custom>(path: "/v3/bill/6/hr/1?format=json"))
    let value = try await client(mock).value(for: CongressRequest(endpoint: endpoint))
    #expect(value.request.object?["congress"] == .string("6"))
  }

  @Test("Custom collection endpoints yield only their first response")
  func customCollectionEndpointsYieldOnlyTheirFirstResponse() async throws {
    let mock = MockTransport(results: [
      .success(Response(body: try Fixture.bills6_first.data(), status: .ok))
    ])
    let request = CongressRequest(
      endpoint: Endpoint.bills(matching: try BillQuery(congress: 6, limit: 2)))
    var iterator = client(mock).pages(for: request).makeAsyncIterator()
    #expect(try await iterator.next()?.value.bills.count == 2)
    #expect(try await iterator.next() == nil)
  }

  @Test("Every bill execution level returns the same provider record")
  func everyBillExecutionLevelReturnsTheSameProviderRecord() async throws {
    let bytes = try Fixture.bill6.data()
    let mock = MockTransport(
      results: Array(repeating: .success(Response(body: bytes, status: .ok)), count: 5))
    let client = client(mock)
    let key = try BillSourceIdentifier(congress: 6, number: "1", type: .houseBill)
    let stored = CongressRequest.bill(key)
    let everyday = try await client.bill(key)
    #expect(try await client.value(for: .bill(key)) == everyday)
    #expect(try await client.value(for: stored) == everyday)
    #expect(try await client.value(for: .historicalExample) == everyday)
    let receipt = try await client.response(for: .bill(key))
    #expect(receipt.body == bytes)
    #expect(receipt.value == everyday)
    #expect(mock.requests.count == 5)
    for call in mock.requests {
      #expect(call.request.path == "/v3/bill/6/hr/1?format=json")
      #expect(call.request.headerFields[HTTPField.Name("X-Api-Key")!] == "test-key")
      #expect(call.request.headerFields[.userAgent] == "CongressTests")
    }
  }

  @Test("Items drain the current page and early break sends nothing more")
  func itemsDrainTheCurrentPageAndEarlyBreakSendsNothingMore() async throws {
    let mock = MockTransport(results: [
      .success(Response(body: try Fixture.bills6_first.data(), status: .ok))
    ])
    var count = 0
    for try await bill in client(mock).bills(matching: try BillQuery(congress: 6, limit: 2)) {
      #expect(bill.congress == 6)
      count += 1
      if count == 2 { break }
    }
    #expect(count == 2)
    #expect(mock.requests.count == 1)
  }

  @Test("Pages are lazy and independent and retain their exact bytes")
  func pagesAreLazyAndIndependentAndRetainTheirExactBytes() async throws {
    let first = try Fixture.bills6_first.data()
    let second = try Fixture.bills6_next.data()
    let mock = MockTransport(
      results: [first, second, first].map { .success(Response(body: $0, status: .ok)) })
    let pages = client(mock).billPages(matching: try BillQuery(congress: 6, limit: 2))
    var a = pages.makeAsyncIterator()
    var b = pages.makeAsyncIterator()
    #expect(mock.requests.isEmpty)
    #expect(try await a.next()?.body == first)
    #expect(mock.requests.count == 1)
    #expect(try await a.next()?.body == second)
    #expect(mock.requests.last?.request.path == "/v3/bill/6?offset=2&limit=2&format=json")
    #expect(try await b.next()?.body == first)
    #expect(mock.requests.count == 3)
  }

  @Test("Redirects are refused before any credential can reach another origin")
  func redirectsAreRefusedBeforeAnyCredentialCanReachAnotherOrigin() async throws {
    let mock = MockTransport(results: [
      .success(Response(headers: [.location: "https://example.com/stolen"], status: .found))
    ])
    do {
      _ = try await client(mock).value(for: .historicalExample)
      Issue.record("Expected a redirect refusal")
    } catch CongressDataError.transport(.httpStatus(_, let code, _)) {
      #expect(code == 302)
    }
    #expect(mock.requests.count == 1)
  }
  private func client(_ transport: MockTransport) -> CongressDataClient {
    CongressDataClient(
      configuration: .init(apiKey: "test-key", userAgent: "CongressTests"), transport: transport)
  }
}

private actor Gate {
  private var continuations: [CheckedContinuation<Void, Never>] = []
  private var isOpen = false

  func open() {
    isOpen = true
    for continuation in continuations { continuation.resume() }
    continuations = []
  }

  func wait() async {
    if isOpen { return }
    await withCheckedContinuation { continuations.append($0) }
  }
}
