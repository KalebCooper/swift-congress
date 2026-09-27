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

extension CongressRequest where Response == MemberDetail {
  static var formerSenatorExample: Self {
    get throws { .member(try MemberIdentifier(rawValue: "L000174")) }
  }
}

private let memberOrigin = "https://api.congress.gov/v3/member/congress/117"

/// A labeled provider link substituted into a recorded page.
struct MemberLinkCase: CustomTestStringConvertible, Sendable {
  let label: String
  let pagination: [String: JSONValue]
  var testDescription: String { label }

  init(_ label: String, next link: String?) {
    self.label = label
    var pagination: [String: JSONValue] = ["count": .number(557)]
    if let link { pagination["next"] = .string(link) }
    self.pagination = pagination
  }
}

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct MemberTests {
  private static let firstPath =
    "/v3/member/congress/117?currentMember=false&format=json&limit=2&offset=0"

  @Test(
    "A member continuation that changes the route or filters is refused before transmission",
    arguments: [
      MemberLinkCase(
        "changed member status",
        next: memberOrigin + "?currentMember=true&offset=2&limit=2&format=json"),
      MemberLinkCase("dropped member status", next: memberOrigin + "?offset=2&limit=2&format=json"),
      MemberLinkCase(
        "changed Congress",
        next:
          "https://api.congress.gov/v3/member/congress/118?currentMember=false&offset=2&limit=2&format=json"
      ),
      MemberLinkCase(
        "changed page size",
        next: memberOrigin + "?currentMember=false&offset=2&limit=3&format=json"),
      MemberLinkCase(
        "duplicate query parameter",
        next: memberOrigin + "?currentMember=false&offset=2&offset=4&limit=2&format=json"),
      MemberLinkCase(
        "dot segment",
        next:
          "https://api.congress.gov/v3/member/congress/118/../117?currentMember=false&offset=2&limit=2&format=json"
      ),
      MemberLinkCase(
        "foreign origin",
        next:
          "https://example.com/v3/member/congress/117?currentMember=false&offset=2&limit=2&format=json"
      ),
      MemberLinkCase(
        "credential in authority",
        next:
          "https://user:secret@api.congress.gov/v3/member/congress/117?currentMember=false&offset=2&limit=2&format=json"
      ),
      MemberLinkCase(
        "credential in query",
        next: memberOrigin + "?currentMember=false&offset=2&limit=2&format=json&api_key=secret"),
    ])
  func aMemberContinuationThatChangesTheRouteOrFiltersIsRefusedBeforeTransmission(
    link: MemberLinkCase
  ) async throws {
    try await expectRefusedContinuation(link)
  }

  @Test("A terminal member page ends the traversal after one request")
  func aTerminalMemberPageEndsTheTraversalAfterOneRequest() async throws {
    let bytes = try Fixture.members117_terminal.data()
    let mock = MockTransport(
      results: Array(repeating: .success(Response(body: bytes, status: .ok)), count: 2))
    let query = try MemberQuery(limit: 2, offset: 556, scope: .congress(117))
    var pages = client(mock).memberPages(matching: query).makeAsyncIterator()
    #expect(try await pages.next()?.value.members.map(\.bioguideId) == ["H000324"])
    #expect(try await pages.next() == nil)
    var members = client(mock).members(matching: query).makeAsyncIterator()
    #expect(try await members.next()?.bioguideId == "H000324")
    #expect(try await members.next() == nil)
    #expect(mock.requests.count == 2)
    for call in mock.requests {
      #expect(
        call.request.path
          == "/v3/member/congress/117?currentMember=false&format=json&limit=2&offset=556")
    }
  }

  @Test(
    "An invalid member continuation fails before yielding the page",
    arguments: [
      MemberLinkCase("missing link with records remaining", next: nil),
      MemberLinkCase(
        "repeated offset", next: memberOrigin + "?currentMember=false&offset=0&limit=2&format=json"),
      MemberLinkCase(
        "nonprogressing offset",
        next: memberOrigin + "?currentMember=false&offset=1&limit=2&format=json"),
      MemberLinkCase(
        "malformed link",
        next: "api.congress.gov/v3/member/congress/117?currentMember=false&offset=2&limit=2"),
    ])
  func anInvalidMemberContinuationFailsBeforeYieldingThePage(link: MemberLinkCase) async throws {
    try await expectRefusedContinuation(link)
  }

  @Test("Cancellation before a member traversal starts sends no request")
  func cancellationBeforeAMemberTraversalStartsSendsNoRequest() async throws {
    let mock = MockTransport()
    let resume = Gate()
    let members = client(mock).members(matching: try MemberQuery(limit: 2, scope: .congress(117)))
    let task = Task {
      await resume.wait()
      var iterator = members.makeAsyncIterator()
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

  @Test("Cancellation while members are buffered returns no additional member")
  func cancellationWhileMembersAreBufferedReturnsNoAdditionalMember() async throws {
    let mock = MockTransport(results: [
      .success(Response(body: try Fixture.members117_first.data(), status: .ok))
    ])
    let members = client(mock).members(matching: try MemberQuery(limit: 2, scope: .congress(117)))
    let ready = Gate()
    let resume = Gate()
    let task = Task {
      var iterator = members.makeAsyncIterator()
      #expect(try await iterator.next()?.bioguideId == "R000579")
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

  @Test("Every member detail execution level returns the same provider record")
  func everyMemberDetailExecutionLevelReturnsTheSameProviderRecord() async throws {
    let bytes = try Fixture.member_L000174.data()
    let mock = MockTransport(
      results: Array(repeating: .success(Response(body: bytes, status: .ok)), count: 6))
    let client = client(mock)
    let identifier = try MemberIdentifier(rawValue: "L000174")
    let stored = CongressRequest.member(identifier)
    let everyday = try await client.member(identifier)
    #expect(everyday.member.bioguideId == "L000174")
    #expect(try await client.value(for: .member(identifier)) == everyday)
    #expect(try await client.value(for: stored) == everyday)
    #expect(try await client.value(for: .formerSenatorExample) == everyday)
    #expect(try await client.send(.member(identifier)) == everyday)
    let receipt = try await client.response(for: .member(identifier))
    #expect(receipt.body == bytes)
    #expect(receipt.value == everyday)
    #expect(mock.requests.count == 6)
    for call in mock.requests {
      #expect(call.request.path == "/v3/member/L000174?format=json")
      #expect(call.request.headerFields[HTTPField.Name("X-Api-Key")!] == "test-key")
      #expect(call.request.headerFields[.userAgent] == "CongressTests")
    }
  }

  @Test("Later member page failures end the iterator with typed errors and quota headers")
  func laterMemberPageFailuresEndTheIteratorWithTypedErrorsAndQuotaHeaders() async throws {
    let first = try Fixture.members117_first.data()
    let mock = MockTransport(results: [
      .success(Response(body: first, status: .ok)),
      .success(Response(headers: [.retryAfter: "60"], status: .tooManyRequests)),
      .success(Response(body: first, status: .ok)),
      .success(Response(body: Data("{}".utf8), status: .ok)),
    ])
    let pages = client(mock).memberPages(
      matching: try MemberQuery(limit: 2, scope: .congress(117)))
    var limited = pages.makeAsyncIterator()
    _ = try await limited.next()
    do {
      _ = try await limited.next(); Issue.record("Expected a quota failure")
    } catch CongressDataError.transport(.httpStatus(_, let code, let headers)) {
      #expect(code == 429); #expect(headers[.retryAfter] == "60")
    }
    #expect(try await limited.next() == nil)
    #expect(mock.requests.count == 2)
    var malformed = pages.makeAsyncIterator()
    _ = try await malformed.next()
    do {
      _ = try await malformed.next(); Issue.record("Expected a decoding failure")
    } catch CongressDataError.decoding {}
    #expect(try await malformed.next() == nil)
    #expect(mock.requests.count == 4)
  }

  @Test("Member construction sends nothing and the first request fetches one page")
  func memberConstructionSendsNothingAndTheFirstRequestFetchesOnePage() async throws {
    let mock = MockTransport(results: [
      .success(Response(body: try Fixture.members117_first.data(), status: .ok))
    ])
    let query = try MemberQuery(limit: 2, scope: .congress(117))
    let request = CongressRequest.members(matching: query)
    let client = client(mock)
    _ = client.members(matching: query).makeAsyncIterator()
    _ = client.items(for: request).makeAsyncIterator()
    var pages = client.memberPages(matching: query).makeAsyncIterator()
    #expect(mock.requests.isEmpty)
    #expect(try await pages.next()?.value.members.count == 2)
    #expect(mock.requests.count == 1)
    let call = try #require(mock.requests.first)
    #expect(Endpoint.members(matching: query).path == Self.firstPath)
    #expect(call.request.path == Self.firstPath)
    #expect(call.request.headerFields[HTTPField.Name("X-Api-Key")!] == "test-key")
    #expect(call.request.headerFields[.userAgent] == "CongressTests")
  }

  @Test("Member items drain the current page and iterators start independently")
  func memberItemsDrainTheCurrentPageAndIteratorsStartIndependently() async throws {
    let first = try Fixture.members117_first.data()
    let mock = MockTransport(
      results: Array(repeating: .success(Response(body: first, status: .ok)), count: 3))
    let members = client(mock).members(matching: try MemberQuery(limit: 2, scope: .congress(117)))
    var identifiers: [String] = []
    for try await member in members {
      identifiers.append(member.bioguideId)
      if identifiers.count == 2 { break }
    }
    #expect(identifiers == ["R000579", "M001212"])
    #expect(mock.requests.count == 1)
    var a = members.makeAsyncIterator()
    var b = members.makeAsyncIterator()
    #expect(try await a.next()?.bioguideId == "R000579")
    #expect(mock.requests.count == 2)
    #expect(try await b.next()?.bioguideId == "R000579")
    #expect(try await a.next()?.bioguideId == "M001212")
    #expect(mock.requests.count == 3)
    #expect(mock.requests.allSatisfy { $0.request.path == Self.firstPath })
  }

  @Test("Member pages follow the provider link and retain their exact bytes")
  func memberPagesFollowTheProviderLinkAndRetainTheirExactBytes() async throws {
    let first = try Fixture.members117_first.data()
    let second = try Fixture.members117_next.data()
    let current = try Fixture.members117_current.data()
    let mock = MockTransport(results: [
      .success(Response(body: first, status: .ok)),
      .success(Response(body: second, status: .ok)),
      .success(Response(body: current, status: .ok)),
      .success(Response(status: .serviceUnavailable)),
    ])
    var pages = client(mock).memberPages(
      matching: try MemberQuery(limit: 2, scope: .congress(117))
    ).makeAsyncIterator()
    let page = try #require(try await pages.next())
    #expect(page.body == first)
    #expect(
      page.value.pagination.next
        == "https://api.congress.gov/v3/member/congress/117?currentMember=false&offset=2&limit=2&format=json"
    )
    let next = try #require(try await pages.next())
    #expect(next.body == second)
    #expect(next.value.members.map(\.bioguideId) == ["F000472", "M001205"])
    #expect(mock.requests.count == 2)
    #expect(
      mock.requests.last?.request.path
        == "/v3/member/congress/117?currentMember=false&offset=2&limit=2&format=json")

    var serving = client(mock).memberPages(
      matching: try MemberQuery(currentMember: true, limit: 2, scope: .congress(117))
    ).makeAsyncIterator()
    #expect(try await serving.next()?.body == current)
    #expect(
      mock.requests.last?.request.path
        == "/v3/member/congress/117?currentMember=true&format=json&limit=2&offset=0")
    await #expect(throws: CongressDataError.self) { _ = try await serving.next() }
    #expect(mock.requests.count == 4)
    #expect(
      mock.requests.last?.request.path
        == "/v3/member/congress/117?currentMember=true&offset=2&limit=2&format=json")
  }

  @Test("Member value, send, and custom requests retrieve only one response")
  func memberValueSendAndCustomRequestsRetrieveOnlyOneResponse() async throws {
    let first = try Fixture.members117_first.data()
    let mock = MockTransport(
      results: Array(repeating: .success(Response(body: first, status: .ok)), count: 3))
    let client = client(mock)
    let query = try MemberQuery(limit: 2, scope: .congress(117))
    let value = try await client.value(for: .members(matching: query))
    #expect(value.members.map(\.bioguideId) == ["R000579", "M001212"])
    #expect(try await client.send(.members(matching: query)) == value)
    var custom = client.pages(for: CongressRequest(endpoint: .members(matching: query)))
      .makeAsyncIterator()
    #expect(try await custom.next()?.value == value)
    #expect(try await custom.next() == nil)
    #expect(mock.requests.count == 3)
    #expect(mock.requests.allSatisfy { $0.request.path == Self.firstPath })
  }

  private func client(_ transport: MockTransport) -> CongressDataClient {
    CongressDataClient(
      configuration: .init(apiKey: "test-key", userAgent: "CongressTests"), transport: transport)
  }

  private func expectRefusedContinuation(_ link: MemberLinkCase) async throws {
    var object = try JSONDecoder().decode(
      [String: JSONValue].self, from: Fixture.members117_first.data())
    object["pagination"] = .object(link.pagination)
    let mock = MockTransport(results: [
      .success(Response(body: try JSONEncoder().encode(object), status: .ok))
    ])
    var pages = client(mock).memberPages(
      matching: try MemberQuery(limit: 2, scope: .congress(117))
    ).makeAsyncIterator()
    do {
      _ = try await pages.next(); Issue.record("Expected an invalid continuation")
    } catch CongressDataError.invalidContinuation {}
    #expect(try await pages.next() == nil)
    #expect(mock.requests.count == 1)
  }
}
