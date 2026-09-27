#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import SwiftCongressDataModels
import SwiftCongressDataTestSupport
import Testing

extension CongressRequest where Response == MemberDetail {
  static var formerSenatorExample: Self {
    get throws { .member(try MemberIdentifier(rawValue: "L000174")) }
  }
}

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct MemberModelsTests {
  private static let listFixtures: [Fixture] = [
    .members_default_first, .members_default_next, .members_first, .members_window,
    .members117_first, .members117_next, .members117_terminal, .members117_current,
  ]

  private func decodePage(_ fixture: Fixture) throws -> MemberPage {
    try JSONDecoder().decode(MemberPage.self, from: fixture.data())
  }

  private func decodePage(_ fixture: Fixture, mutating: (inout [String: JSONValue]) -> Void) throws
    -> MemberPage
  {
    var object = try JSONDecoder().decode([String: JSONValue].self, from: fixture.data())
    mutating(&object)
    return try JSONDecoder().decode(MemberPage.self, from: JSONEncoder().encode(object))
  }

  @Test(
    "All source fields survive member detail decoding and encoding",
    arguments: [Fixture.member_A000375, .member_H000324, .member_L000174, .member_P000610])
  func allSourceFieldsSurviveMemberDetailDecodingAndEncoding(fixture: Fixture) throws {
    let bytes = try fixture.data()
    let detail = try JSONDecoder().decode(MemberDetail.self, from: bytes)
    let original = try JSONDecoder().decode(JSONValue.self, from: bytes)
    let encoded = try JSONEncoder().encode(detail)
    #expect(try JSONDecoder().decode(JSONValue.self, from: encoded) == original)
    #expect(detail.member.bioguideId == String(fixture.rawValue.dropFirst(7).dropLast(5)))
    #expect(detail.member.birthYear?.count == 4)
    #expect(detail.member.rawFields["partyHistory"]?.array?.isEmpty == false)
    #expect(detail.member.sponsoredLegislation?.url?.hasPrefix("https://api.congress.gov/") == true)
    #expect(detail.request?.object?["format"] == .string("json"))
  }

  @Test(
    "All source fields survive member page decoding and encoding",
    arguments: MemberModelsTests.listFixtures)
  func allSourceFieldsSurviveMemberPageDecodingAndEncoding(fixture: Fixture) throws {
    let bytes = try fixture.data()
    let page = try JSONDecoder().decode(MemberPage.self, from: bytes)
    let original = try JSONDecoder().decode(JSONValue.self, from: bytes)
    let encoded = try JSONEncoder().encode(page)
    #expect(try JSONDecoder().decode(JSONValue.self, from: encoded) == original)
    #expect(page.items.map(\.bioguideId) == page.members.map(\.bioguideId))
    #expect(!page.members.isEmpty)
    #expect(page.members.allSatisfy({ $0.depiction?.imageUrl != nil }))
  }

  @Test("List terms are read from the source item wrapper")
  func listTermsAreReadFromTheSourceItemWrapper() throws {
    let page = try decodePage(.members117_first)
    let first = try #require(page.members.first)
    #expect(first.bioguideId == "R000579")
    #expect(first.terms?.count == 1)
    #expect(first.terms?.first?.chamber == "House of Representatives")
    #expect(first.terms?.first?.startYear == 2022)
    #expect(first.terms?.first?.endYear == nil)
    #expect(first.rawFields["terms"]?.object?.keys.sorted() == ["item"])
    let window = try decodePage(.members_window)
    #expect(window.members.first?.terms?.first?.endYear == 2023)
    #expect(window.members.first?.terms?.first?.startYear == 2008)
  }

  @Test("Detail terms decode as a bare array with Congress and role")
  func detailTermsDecodeAsABareArrayWithCongressAndRole() throws {
    let former = try JSONDecoder().decode(MemberDetail.self, from: Fixture.member_L000174.data())
    #expect(former.member.currentMember == false)
    #expect(former.member.terms?.count == 24)
    let first = try #require(former.member.terms?.first)
    #expect(first.chamber == "Senate")
    #expect(first.congress == 94)
    #expect(first.district == nil)
    #expect(first.endYear == 1977)
    #expect(first.memberType == "Senator")
    #expect(first.startYear == 1975)
    #expect(first.stateCode == "VT")
    #expect(first.stateName == "Vermont")
    #expect(former.member.rawFields["terms"]?.array?.count == 24)
    let current = try JSONDecoder().decode(MemberDetail.self, from: Fixture.member_A000375.data())
    #expect(current.member.currentMember == true)
    #expect(current.member.district == 19)
    #expect(current.member.terms?.first?.district == 19)
    #expect(current.member.terms?.last?.endYear == nil)
  }

  @Test("A delegate keeps no district in its detail and zero in a list entry")
  func aDelegateKeepsNoDistrictInItsDetailAndZeroInAListEntry() throws {
    let delegate = try JSONDecoder().decode(MemberDetail.self, from: Fixture.member_P000610.data())
    #expect(delegate.member.district == nil)
    #expect(delegate.member.rawFields["district"] == nil)
    #expect(delegate.member.state == "Virgin Islands")
    #expect(delegate.member.terms?.allSatisfy({ $0.memberType == "Delegate" }) == true)
    #expect(delegate.member.terms?.allSatisfy({ $0.district == nil }) == true)
    #expect(delegate.member.terms?.first?.stateCode == "VI")
    // No stored list fixture carries district 0; the recorded district-0 list entry exists only in
    // the unstored selection page, so zero preservation is proven with a labeled mutation.
    let page = try decodePage(.members117_first) { object in
      var members = object["members"]?.array ?? []
      var entry = members[0].object ?? [:]
      entry["district"] = .number(0)
      members[0] = .object(entry)
      object["members"] = .array(members)
    }
    #expect(page.members.first?.district == 0)
    #expect(page.members.first?.rawFields["district"] == .number(0))
    // The recorded senator entry omits the key rather than publishing a null.
    let senators = try decodePage(.members_first)
    #expect(senators.members.first?.bioguideId == "G000608")
    #expect(senators.members.first?.district == nil)
    #expect(senators.members.first?.rawFields["district"] == nil)
  }

  @Test("A published death year decodes as the source string")
  func aPublishedDeathYearDecodesAsTheSourceString() throws {
    let deceased = try JSONDecoder().decode(MemberDetail.self, from: Fixture.member_H000324.data())
    #expect(deceased.member.birthYear == "1936")
    #expect(deceased.member.currentMember == false)
    #expect(deceased.member.deathYear == "2021")
    #expect(deceased.member.rawFields["deathYear"] == .string("2021"))
    #expect(deceased.member.terms?.last?.endYear == 2021)
    // The recorded living members omit the key; a null value would also decode as nil.
    for fixture in [Fixture.member_A000375, .member_L000174, .member_P000610] {
      let living = try JSONDecoder().decode(MemberDetail.self, from: fixture.data())
      #expect(living.member.deathYear == nil)
      #expect(living.member.rawFields["deathYear"] == nil)
    }
  }

  @Test("Unknown vocabulary, nulls, and unknown keys are preserved")
  func unknownVocabularyNullsAndUnknownKeysArePreserved() throws {
    let page = try decodePage(.members117_first) { object in
      var members = object["members"]?.array ?? []
      var entry = members[0].object ?? [:]
      entry["partyName"] = .string("Anti-Administration")
      entry["state"] = .null
      entry["terms"] = .object([
        "item": .array([
          .object(["chamber": .string("Upper House"), "startYear": .null, "note": .string("x")])
        ])
      ])
      entry["updateDate"] = .null
      entry["url"] = .null
      entry["unknownKey"] = .boolean(true)
      members[0] = .object(entry)
      var absent = members[1].object ?? [:]
      absent["terms"] = .null
      absent["depiction"] = .null
      members[1] = .object(absent)
      object["members"] = .array(members)
    }
    let first = try #require(page.members.first)
    #expect(first.partyName == "Anti-Administration")
    #expect(first.state == nil)
    #expect(first.rawFields["state"] == .null)
    #expect(first.terms?.first?.chamber == "Upper House")
    #expect(first.terms?.first?.startYear == nil)
    #expect(first.terms?.first?.rawFields["note"] == .string("x"))
    #expect(first.updateDate == nil)
    #expect(first.url == nil)
    #expect(first.rawFields["unknownKey"] == .boolean(true))
    let second = try #require(page.members.last)
    #expect(second.terms == nil)
    #expect(second.depiction == nil)
    #expect(second.rawFields["terms"] == .null)

    var object = try JSONDecoder().decode(
      [String: JSONValue].self, from: Fixture.member_P000610.data())
    var member = object["member"]?.object ?? [:]
    var terms = member["terms"]?.array ?? []
    terms[0] = .object(["memberType": .string("Resident Commissioner"), "congress": .null])
    member["terms"] = .array(terms)
    member["birthYear"] = .null
    member["deathYear"] = .string("1900")
    member["currentMember"] = .null
    object["member"] = .object(member)
    let detail = try JSONDecoder().decode(MemberDetail.self, from: JSONEncoder().encode(object))
    #expect(detail.member.terms?.first?.memberType == "Resident Commissioner")
    #expect(detail.member.terms?.first?.congress == nil)
    #expect(detail.member.terms?.first?.chamber == nil)
    #expect(detail.member.birthYear == nil)
    #expect(detail.member.deathYear == "1900")
    #expect(detail.member.currentMember == nil)
    #expect(detail.member.rawFields["currentMember"] == .null)
  }

  @Test("A false member filter can return currently serving members")
  func aFalseMemberFilterCanReturnCurrentlyServingMembers() throws {
    let unfiltered = try decodePage(.members117_first)
    let serving = try decodePage(.members117_current)
    #expect(unfiltered.pagination.count == 557)
    #expect(serving.pagination.count == 377)
    #expect(unfiltered.members.prefix(2).map(\.bioguideId) == ["R000579", "M001212"])
    #expect(serving.members.prefix(2).map(\.bioguideId) == ["R000579", "M001212"])
  }

  @Test("An unscoped false member filter matched the omitted filter in recorded pages")
  func anUnscopedFalseMemberFilterMatchedTheOmittedFilterInRecordedPages() throws {
    let filtered = try decodePage(.members_default_first)
    let omitted = try decodePage(.members_first)
    #expect(filtered.pagination.count == 2696)
    #expect(omitted.pagination.count == 2696)
    #expect(filtered.members.map(\.bioguideId) == ["G000608", "W000832"])
    #expect(omitted.members.map(\.bioguideId) == ["G000608", "W000832"])
  }

  @Test("Member queries encode exact routes")
  func memberQueriesEncodeExactRoutes() throws {
    #expect(
      Endpoint.members(matching: try MemberQuery()).path
        == "/v3/member?currentMember=false&format=json&limit=20&offset=0")
    #expect(
      Endpoint.members(matching: try MemberQuery(currentMember: nil, limit: 2)).path
        == "/v3/member?format=json&limit=2&offset=0")
    #expect(
      Endpoint.members(matching: try MemberQuery(limit: 2, scope: .congress(117))).path
        == "/v3/member/congress/117?currentMember=false&format=json&limit=2&offset=0")
    #expect(
      Endpoint.members(
        matching: try MemberQuery(currentMember: true, offset: 4, scope: .congress(1))
      )
      .path == "/v3/member/congress/1?currentMember=true&format=json&limit=20&offset=4")
    #expect(
      Endpoint.members(
        matching: try MemberQuery(
          currentMember: nil, fromDateTime: "2026-09-01T00:00:00Z", limit: 2,
          toDateTime: "2026-09-25T00:00:00Z")
      ).path
        == "/v3/member?format=json&fromDateTime=2026-09-01T00:00:00Z&limit=2&offset=0&toDateTime=2026-09-25T00:00:00Z"
    )
    #expect(
      Endpoint.members(matching: try MemberQuery(fromDateTime: "2026-09-01T00:00:00+00:00")).path
        == "/v3/member?currentMember=false&format=json&fromDateTime=2026-09-01T00:00:00%2B00:00&limit=20&offset=0"
    )
    let query = try MemberQuery(limit: 2, scope: .congress(117))
    #expect(query.currentMember == false)
    #expect(query.page.limit == 2)
    #expect(query.page.offset == 0)
    #expect(query.scope == .congress(117))
  }

  @Test("Invalid member queries fail before any request")
  func invalidMemberQueriesFailBeforeAnyRequest() {
    #expect(throws: CongressInputError.invalidQuery) { try MemberQuery(scope: .congress(0)) }
    #expect(throws: CongressInputError.invalidQuery) { try MemberQuery(scope: .congress(-1)) }
    #expect(throws: CongressInputError.invalidQuery) { try MemberQuery(limit: 0) }
    #expect(throws: CongressInputError.invalidQuery) { try MemberQuery(limit: 251) }
    #expect(throws: CongressInputError.invalidQuery) { try MemberQuery(offset: -1) }
    #expect(throws: CongressInputError.invalidQuery) {
      try MemberQuery(fromDateTime: "2026-09-01T00:00:00Z", scope: .congress(117))
    }
    #expect(throws: CongressInputError.invalidQuery) {
      try MemberQuery(scope: .congress(117), toDateTime: "2026-09-25T00:00:00Z")
    }
    #expect(throws: CongressInputError.invalidQuery) {
      try MemberQuery(fromDateTime: "2026-09-01T00:00:00Z", limit: 0)
    }
  }

  @Test(
    "Member identifiers accept safe path components only",
    arguments: [
      ("L000174", true), ("a000375", true), ("x", true), ("A-1_b", true),
      ("", false), ("L000174/", false), ("..", false), ("L.174", false), ("%4C", false),
      ("L\u{01}174", false), ("L 174", false), ("L?x", false), ("L#x", false), ("É", false),
      ("L~1", false),
    ])
  func memberIdentifiersAcceptSafePathComponentsOnly(candidate: String, accepted: Bool) throws {
    if accepted {
      #expect(try MemberIdentifier(rawValue: candidate).rawValue == candidate)
    } else {
      #expect(throws: CongressInputError.invalidMemberIdentifier) {
        try MemberIdentifier(rawValue: candidate)
      }
    }
  }

  @Test("Member endpoints preserve identifier spelling")
  func memberEndpointsPreserveIdentifierSpelling() throws {
    #expect(
      Endpoint.member(try MemberIdentifier(rawValue: "a000375")).path
        == "/v3/member/a000375?format=json")
    #expect(
      Endpoint.member(try MemberIdentifier(rawValue: "L000174")).path
        == "/v3/member/L000174?format=json")
  }

  @Test("Continuation follows the recorded scoped member links")
  func continuationFollowsTheRecordedScopedMemberLinks() throws {
    let endpoint = Endpoint.members(matching: try MemberQuery(limit: 2, scope: .congress(117)))
    let next = try CongressContinuation.next(
      after: decodePage(.members117_first), endpoint: endpoint)
    #expect(
      next?.path == "/v3/member/congress/117?currentMember=false&offset=2&limit=2&format=json")
    let third = try CongressContinuation.next(
      after: decodePage(.members117_next), endpoint: #require(next))
    #expect(
      third?.path == "/v3/member/congress/117?currentMember=false&offset=4&limit=2&format=json")
    let terminal = try decodePage(.members117_terminal)
    #expect(terminal.members.count == 1)
    #expect(terminal.pagination.next == nil)
    #expect(terminal.pagination.prev != nil)
    let lastLink = try #require(
      URL(
        string:
          "https://api.congress.gov/v3/member/congress/117?currentMember=false&offset=556&limit=2&format=json"
      ))
    let last = try #require(Endpoint<MemberPage>(link: lastLink))
    #expect(try CongressContinuation.next(after: terminal, endpoint: last) == nil)
    #expect(
      try CongressContinuation.next(
        after: terminal,
        endpoint: .members(matching: MemberQuery(limit: 2, offset: 556, scope: .congress(117))))
        == nil)
    let current = try CongressContinuation.next(
      after: decodePage(.members117_current),
      endpoint: .members(
        matching: MemberQuery(currentMember: true, limit: 2, scope: .congress(117))))
    #expect(
      current?.path == "/v3/member/congress/117?currentMember=true&offset=2&limit=2&format=json")
  }

  @Test("Continuation preserves the modification window")
  func continuationPreservesTheModificationWindow() throws {
    let query = try MemberQuery(
      currentMember: nil, fromDateTime: "2026-09-01T00:00:00Z", limit: 2,
      toDateTime: "2026-09-25T00:00:00Z")
    let next = try CongressContinuation.next(
      after: decodePage(.members_window), endpoint: .members(matching: query))
    #expect(
      next?.path
        == "/v3/member?fromDateTime=2026-09-01T00:00:00Z&toDateTime=2026-09-25T00:00:00Z&offset=2&limit=2&format=json"
    )
    let unscoped = try CongressContinuation.next(
      after: decodePage(.members_first),
      endpoint: .members(matching: MemberQuery(currentMember: nil, limit: 2)))
    #expect(unscoped?.path == "/v3/member?offset=2&limit=2&format=json")
  }

  @Test("Continuation keeps the default member status on the unscoped inventory")
  func continuationKeepsTheDefaultMemberStatusOnTheUnscopedInventory() throws {
    let query = try MemberQuery(limit: 2)
    #expect(
      Endpoint.members(matching: query).path
        == "/v3/member?currentMember=false&format=json&limit=2&offset=0")
    let first = try decodePage(.members_default_first)
    #expect(
      first.pagination.next
        == "https://api.congress.gov/v3/member?currentMember=false&offset=2&limit=2&format=json")
    let next = try CongressContinuation.next(after: first, endpoint: .members(matching: query))
    #expect(next?.path == "/v3/member?currentMember=false&offset=2&limit=2&format=json")
    let second = try decodePage(.members_default_next)
    #expect(second.members.map(\.bioguideId) == ["B001328", "G000607"])
    let recorded = try #require(next)
    let third = try CongressContinuation.next(after: second, endpoint: recorded)
    #expect(third?.path == "/v3/member?currentMember=false&offset=4&limit=2&format=json")
  }

  @Test(
    "A continuation that changes a member filter fails before yielding the page",
    arguments: [
      "https://api.congress.gov/v3/member/congress/117?currentMember=true&offset=2&limit=2&format=json",
      "https://api.congress.gov/v3/member/congress/117?offset=2&limit=2&format=json",
      "https://api.congress.gov/v3/member/congress/118?currentMember=false&offset=2&limit=2&format=json",
      "https://api.congress.gov/v3/member?currentMember=false&offset=2&limit=2&format=json",
      "https://api.congress.gov/v3/member/congress/117?currentMember=false&offset=2&offset=4&limit=2&format=json",
      "https://example.com/v3/member/congress/117?currentMember=false&offset=2&limit=2&format=json",
      "https://api.congress.gov/v3/member/congress/117?currentMember=false&offset=2&limit=2&format=json&api_key=secret",
    ])
  func aContinuationThatChangesAMemberFilterFailsBeforeYieldingThePage(link: String) throws {
    let page = try decodePage(.members117_first) { object in
      object["pagination"] = .object(["count": .number(557), "next": .string(link)])
    }
    #expect(throws: CongressPaginationError.invalidContinuation) {
      try CongressContinuation.next(
        after: page, endpoint: .members(matching: MemberQuery(limit: 2, scope: .congress(117))))
    }
    let window = try decodePage(.members_window) { object in
      object["pagination"] = .object([
        "count": .number(97),
        "next": .string(
          "https://api.congress.gov/v3/member?fromDateTime=2026-09-01T00:00:00Z&offset=2&limit=2&format=json"
        ),
      ])
    }
    #expect(throws: CongressPaginationError.invalidContinuation) {
      try CongressContinuation.next(
        after: window,
        endpoint: .members(
          matching: MemberQuery(
            currentMember: nil, fromDateTime: "2026-09-01T00:00:00Z", limit: 2,
            toDateTime: "2026-09-25T00:00:00Z")))
    }
  }

  @Test("Contextual and stored member factories infer concrete responses")
  func contextualAndStoredMemberFactoriesInferConcreteResponses() throws {
    struct Custom: Decodable, Sendable { let request: JSONValue }
    let identifier = try MemberIdentifier(rawValue: "L000174")
    let contextual: CongressRequest<MemberDetail> = .member(identifier)
    let stored = CongressRequest.members(matching: try MemberQuery(limit: 2, scope: .congress(117)))
    let named = try CongressRequest.formerSenatorExample
    let endpoint: Endpoint<MemberPage> = .members(matching: try MemberQuery(currentMember: nil))
    let custom = CongressRequest(
      endpoint: try #require(Endpoint<Custom>(path: "/v3/member/L000174?format=json")))
    #expect(contextual == named)
    #expect(contextual.resolution == .endpoint(.member(identifier)))
    #expect(
      stored.resolution
        == .collection(.members(matching: try MemberQuery(limit: 2, scope: .congress(117)))))
    #expect(endpoint.path == "/v3/member?format=json&limit=20&offset=0")
    let customEndpoint = try #require(Endpoint<Custom>(path: "/v3/member/L000174?format=json"))
    #expect(custom.resolution == .endpoint(customEndpoint))

    let decoded = try JSONDecoder().decode(Custom.self, from: Fixture.member_L000174.data())
    #expect(decoded.request.object?["bioguideId"] == .string("l000174"))
  }
}
