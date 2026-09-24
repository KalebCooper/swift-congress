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
