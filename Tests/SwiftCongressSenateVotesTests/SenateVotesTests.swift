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
    .rollCall(try! SenateVoteIdentifier(congress: 101, number: 1, session: 1))
  }
}

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct SenateVotesTests {
  @Test func everyExecutionLevelUsesTheSameBoundedDecoder() async throws {
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

  @Test func indexAndCrosswalkRemainIndependentRequests() async throws {
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

  @Test func sizeAndStatusFailuresRetainTheirMeaning() async throws {
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
