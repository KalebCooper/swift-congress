import Foundation
import SwiftCongressSenateVotesModels
import SwiftCongressSenateVotesTestSupport
import Testing

import HTTPCore
import HTTPTesting
import HTTPTypes
import SwiftCongressSenateVotes

extension SenateVoteRequest where Response == SenateRollCall {
  static var historicalExample: Self {
    get throws {
      .rollCall(try SenateVoteIdentifier(congress: 101, number: 1, session: 1))
    }
  }
}

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct SenateVotesTests {
  @Test("Cancellation during body reading returns no partial record")
  func cancellationDuringBodyReadingReturnsNoPartialRecord() async throws {
    let ready = Gate(); let resume = Gate()
    let bytes = try Fixture.senate2026.data()
    let chunks = PausedChunks(
      prefix: bytes.prefix(10), ready: ready, resume: resume, suffix: bytes.dropFirst(10))
    let client = SenateVotesClient(
      transport: PausedTransport(chunks: chunks), userAgent: "CancellationTests")
    let id = try SenateVoteIdentifier(congress: 119, number: 240, session: 2)
    let task = Task {
      do {
        _ = try await client.rollCall(id)
        Issue.record("Expected cancellation before decoding the complete record")
      } catch SenateVotesError.transport(.cancelled) {}
    }
    await ready.wait(); task.cancel(); await resume.open(); try await task.value
  }

  @Test("Custom response uses the same executor")
  func customResponseUsesTheSameExecutor() async throws {
    struct Custom: SenateResponse {
      let root: SenateXMLNode
      static func decode(_ data: Data, sourceURL: URL) throws(SenateDecodingError) -> Self {
        Self(root: try SenateXMLCodec.decode(data))
      }
    }
    let id = try SenateVoteIdentifier(congress: 119, number: 240, session: 2)
    let endpoint = try #require(Endpoint<Custom>(path: Endpoint<SenateRollCall>.rollCall(id).path))
    let mock = MockTransport(results: [
      .success(Response(body: try Fixture.senate2026.data(), status: .ok))
    ])
    let client = SenateVotesClient(transport: mock, userAgent: "CustomTests")
    let value = try await client.value(for: SenateVoteRequest(endpoint: endpoint))
    #expect(!value.root.content.isEmpty)
    #expect(mock.requests.count == 1)
    #expect(SenateVotePosition(rawValue: "Future Position").rawValue == "Future Position")
  }

  @Test("Every execution level uses the same bounded decoder")
  func everyExecutionLevelUsesTheSameBoundedDecoder() async throws {
    let bytes = try Fixture.senate1989.data()
    let mock = MockTransport(
      results: Array(repeating: .success(Response(body: bytes, status: .ok)), count: 5))
    let client = SenateVotesClient(transport: mock, userAgent: "SenateTests")
    let id = try SenateVoteIdentifier(congress: 101, number: 1, session: 1)
    let stored = SenateVoteRequest.rollCall(id)
    let value = try await client.rollCall(id)
    #expect(try await client.value(for: stored) == value)
    #expect(try await client.value(for: .historicalExample) == value)
    #expect(try await client.send(.rollCall(id)) == value)
    let receipt = try await client.response(for: .rollCall(id))
    #expect(receipt.body == bytes)
    #expect(receipt.value == value)
    for call in mock.requests {
      #expect(call.request.path == "/legislative/LIS/roll_call_votes/vote1011/vote_101_1_00001.xml")
      #expect(call.request.headerFields[.userAgent] == "SenateTests")
      #expect(call.request.headerFields[HTTPField.Name("X-Api-Key")!] == nil)
    }
  }

  @Test("Index and crosswalk remain independent requests")
  func indexAndCrosswalkRemainIndependentRequests() async throws {
    let mock = MockTransport(results: [
      .success(Response(body: try Fixture.senate_index.data(), status: .ok)),
      .success(Response(body: try Fixture.senate_identities.data(), status: .ok)),
    ])
    let client = SenateVotesClient(transport: mock, userAgent: "SenateTests")
    #expect(!(try await client.index(congress: 119, session: 2)).votes.isEmpty)
    #expect(mock.requests.count == 1)
    #expect(try await client.memberIdentities().identities.count == 100)
    #expect(mock.requests.count == 2)
    #expect(mock.requests[1].request.path == "/legislative/LIS_MEMBER/cvc_member_data.xml")
  }

  @Test("Size and status failures retain their meaning")
  func sizeAndStatusFailuresRetainTheirMeaning() async throws {
    let bytes = try Fixture.senate1989.data()
    let mock = MockTransport(results: [.success(Response(body: bytes, status: .ok))])
    do {
      _ = try await SenateVotesClient(
        maximumResponseBytes: 1, transport: mock, userAgent: "SenateTests"
      ).value(for: .historicalExample)
      Issue.record("Expected body limit")
    } catch SenateVotesError.responseTooLarge {}
    let status = MockTransport(results: [
      .success(Response(headers: [.retryAfter: "60"], status: .tooManyRequests))
    ])
    do {
      _ = try await SenateVotesClient(transport: status, userAgent: "SenateTests").value(
        for: .historicalExample)
      Issue.record("Expected quota error")
    } catch SenateVotesError.transport(.httpStatus(_, let code, let headers)) {
      #expect(code == 429); #expect(headers[.retryAfter] == "60")
    }
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
