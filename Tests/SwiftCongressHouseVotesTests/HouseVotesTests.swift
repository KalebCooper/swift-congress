import Foundation
import SwiftCongressHouseVotesModels
import SwiftCongressHouseVotesTestSupport
import Testing

import HTTPCore
import HTTPTesting
import HTTPTypes
import SwiftCongressHouseVotes

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct HouseVotesTests {
  @Test func allExecutionLevelsRetainSourceBytesAndSendOnlyOneRequest() async throws {
    let bytes = try Fixture.house2026.data()
    let mock = MockTransport(
      results: Array(repeating: .success(Response(body: bytes, status: .ok)), count: 4))
    let client = HouseVotesClient(transport: mock, userAgent: "HouseTests")
    let id = try HouseVoteIdentifier(number: 314, year: 2026)
    let stored = HouseVoteRequest.rollCall(id)
    let value = try await client.rollCall(id)
    #expect(try await client.value(for: stored) == value)
    #expect(try await client.send(.rollCall(id)) == value)
    let receipt = try await client.response(for: .rollCall(id))
    #expect(receipt.body == bytes)
    #expect(receipt.value == value)
    #expect(mock.requests.count == 4)
    for call in mock.requests {
      #expect(call.request.path == "/evs/2026/roll314.xml")
      #expect(call.request.headerFields[.userAgent] == "HouseTests")
      #expect(call.request.headerFields[HTTPField.Name("X-Api-Key")!] == nil)
    }
  }

  @Test func cancellationDuringBodyReadingReturnsNoPartialRecord() async throws {
    let ready = Gate(); let resume = Gate()
    let bytes = try Fixture.house2026.data()
    let chunks = PausedChunks(
      prefix: bytes.prefix(10), ready: ready, resume: resume, suffix: bytes.dropFirst(10))
    let client = HouseVotesClient(
      transport: PausedTransport(chunks: chunks), userAgent: "CancellationTests")
    let id = try HouseVoteIdentifier(number: 314, year: 2026)
    let task = Task {
      do {
        _ = try await client.rollCall(id)
        Issue.record("Expected cancellation before decoding the complete record")
      } catch HouseVotesError.transport(.cancelled) {}
    }
    await ready.wait(); task.cancel(); await resume.open(); try await task.value
  }

  @Test func customResponseUsesTheSameExecutor() async throws {
    struct Custom: HouseResponse {
      let root: HouseXMLNode
      static func decode(_ data: Data, sourceURL: URL) throws(HouseDecodingError) -> Self {
        Self(root: try HouseXMLCodec.decode(data))
      }
    }
    let id = try HouseVoteIdentifier(number: 314, year: 2026)
    let endpoint = try #require(Endpoint<Custom>(path: Endpoint<HouseRollCall>.rollCall(id).path))
    let mock = MockTransport(results: [
      .success(Response(body: try Fixture.house2026.data(), status: .ok))
    ])
    let client = HouseVotesClient(transport: mock, userAgent: "CustomTests")
    let value = try await client.value(for: HouseVoteRequest(endpoint: endpoint))
    #expect(!value.root.content.isEmpty)
    #expect(mock.requests.count == 1)
    #expect(HouseVotePosition(rawValue: "Future Position").rawValue == "Future Position")
  }

  @Test func indexesDoNotFetchSectionsOrVotes() async throws {
    let mock = MockTransport(results: [
      .success(Response(body: try Fixture.house_index.data(), status: .ok))
    ])
    let client = HouseVotesClient(transport: mock, userAgent: "HouseTests")
    #expect(!(try await client.index(year: 2026)).sections.isEmpty)
    #expect(mock.requests.count == 1)
  }

  @Test func oversizedBodiesAndRedirectsFail() async throws {
    let mock = MockTransport(results: [
      .success(Response(body: try Fixture.house2026.data(), status: .ok))
    ])
    let client = HouseVotesClient(
      maximumResponseBytes: 10, transport: mock, userAgent: "HouseTests")
    do {
      _ = try await client.rollCall(number: 314, year: 2026)
      Issue.record("Expected bounded-body failure")
    } catch HouseVotesError.responseTooLarge {}
    let redirect = MockTransport(results: [
      .success(Response(headers: [.location: "https://example.com"], status: .found))
    ])
    do {
      _ = try await HouseVotesClient(transport: redirect, userAgent: "HouseTests").index(year: 2026)
      Issue.record("Expected redirect refusal")
    } catch HouseVotesError.transport(.httpStatus(_, let status, _)) { #expect(status == 302) }
    #expect(redirect.requests.count == 1)
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

private struct PausedChunks: AsyncSequence, Sendable {
  let prefix: Data
  let ready: Gate
  let resume: Gate
  let suffix: Data
  func makeAsyncIterator() -> Iterator { Iterator(base: self) }
  struct Iterator: AsyncIteratorProtocol {
    let base: PausedChunks
    var index = 0
    mutating func next() async -> Data? {
      defer { index += 1 }
      if index == 0 { return base.prefix }
      if index == 1 { await base.ready.open(); await base.resume.wait(); return base.suffix }
      return nil
    }
  }
}

private struct PausedTransport: Transport {
  let chunks: PausedChunks
  func send(_ request: HTTPRequest, body: TransportBody, options: TransportOptions)
    async throws(TransportError) -> Response
  {
    throw .cancelled
  }
  func stream(_ request: HTTPRequest, body: TransportBody, options: TransportOptions)
    async throws(TransportError) -> StreamedResponse
  {
    StreamedResponse(body: StreamedBody(chunks), headers: [:], status: .ok)
  }
}
