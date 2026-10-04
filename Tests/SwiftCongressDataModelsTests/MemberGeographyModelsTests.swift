#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import SwiftCongressDataModels
import SwiftCongressDataTestSupport
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct MemberGeographyModelsTests {
  @Test(
    "Geographic member fixtures preserve every raw field",
    arguments: [
      Fixture.members118_tx15_current,
      Fixture.members118_tx15_historical,
      Fixture.members_ak_current_first,
      Fixture.members_ak_current_terminal,
      Fixture.members_ak_district0_current,
      Fixture.members_ak_historical,
      Fixture.members_dc_district0_current,
      Fixture.members_ny_default_first,
      Fixture.members_ny_default_next,
    ])
  func geographicMemberFixturesPreserveEveryRawField(fixture: Fixture) throws {
    let bytes = try fixture.data()
    let page = try JSONDecoder().decode(MemberPage.self, from: bytes)
    #expect(page.items == page.members)
    #expect(
      try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(page))
        == JSONDecoder().decode(JSONValue.self, from: bytes))
  }

  @Test("Geographic queries encode only supported controls")
  func geographicQueriesEncodeOnlySupportedControls() throws {
    let state = try MemberGeographyQuery(scope: .state(limit: 250, stateCode: "aK"))
    #expect(state.currentMember == false)
    #expect(state.scope == .state(limit: 250, stateCode: "AK"))
    #expect(
      Endpoint.members(matching: state).path
        == "/v3/member/AK?currentMember=false&format=json&limit=250")
    #expect(
      CongressRequest.members(matching: state).resolution == .collection(.members(matching: state)))
    let omitted = try MemberGeographyQuery(currentMember: nil, scope: .state(stateCode: "NY"))
    #expect(Endpoint.members(matching: omitted).path == "/v3/member/NY?format=json")
    let district = try MemberGeographyQuery(
      currentMember: true, scope: .district(district: 0, stateCode: "dc"))
    #expect(
      Endpoint.members(matching: district).path == "/v3/member/DC/0?currentMember=true&format=json")
    let congress = try MemberGeographyQuery(
      scope: .congressDistrict(congress: 118, district: 15, stateCode: "tx"))
    #expect(
      Endpoint.members(matching: congress).path
        == "/v3/member/congress/118/TX/15?currentMember=false&format=json")
    let territory = try MemberGeographyQuery(scope: .district(district: 0, stateCode: "pr"))
    #expect(
      Endpoint.members(matching: territory).path
        == "/v3/member/PR/0?currentMember=false&format=json")
    let minimum = try MemberGeographyQuery(scope: .state(limit: 1, stateCode: "GU"))
    #expect(Endpoint.members(matching: minimum).path.hasSuffix("limit=1"))
  }

  @Test("Geographic queries reject invalid bounds and non ASCII codes")
  func geographicQueriesRejectInvalidBoundsAndNonASCIICodes() throws {
    for code in ["", "A", "AAA", " A", "A/", "12", "éA", "KS", "ＡＫ"] {
      #expect(throws: CongressInputError.invalidQuery) {
        try MemberGeographyQuery(scope: .state(stateCode: code))
      }
      #expect(throws: CongressInputError.invalidQuery) {
        try MemberGeographyQuery(scope: .district(district: 0, stateCode: code))
      }
      #expect(throws: CongressInputError.invalidQuery) {
        try MemberGeographyQuery(
          scope: .congressDistrict(congress: 118, district: 1, stateCode: code))
      }
    }
    #expect(throws: CongressInputError.invalidQuery) {
      try MemberGeographyQuery(scope: .state(limit: 0, stateCode: "AK"))
    }
    #expect(throws: CongressInputError.invalidQuery) {
      try MemberGeographyQuery(scope: .state(limit: 251, stateCode: "AK"))
    }
    #expect(throws: CongressInputError.invalidQuery) {
      try MemberGeographyQuery(scope: .district(district: -1, stateCode: "AK"))
    }
    #expect(throws: CongressInputError.invalidQuery) {
      try MemberGeographyQuery(scope: .congressDistrict(congress: 0, district: 0, stateCode: "AK"))
    }
    #expect(throws: CongressInputError.invalidQuery) {
      try MemberGeographyQuery(
        scope: .congressDistrict(congress: 118, district: -1, stateCode: "AK"))
    }
  }

  @Test("Geographic records retain absent and changed districts")
  func geographicRecordsRetainAbsentAndChangedDistricts() throws {
    for fixture in [Fixture.members_ak_district0_current, .members_dc_district0_current] {
      let page = try JSONDecoder().decode(MemberPage.self, from: fixture.data())
      #expect(page.items.count == 1)
      #expect(page.items[0].district == nil)
      #expect(page.items[0].rawFields["district"] == nil)
    }
    let historical = try JSONDecoder().decode(
      MemberPage.self, from: Fixture.members118_tx15_historical.data())
    #expect(historical.items.map(\.bioguideId) == ["G000581", "D000594"])
    #expect(historical.items.map(\.district) == [34, 15])
    let current = try JSONDecoder().decode(
      MemberPage.self, from: Fixture.members118_tx15_current.data())
    #expect(current.items.map(\.bioguideId) == ["D000594"])
    let alaska = try JSONDecoder().decode(
      MemberPage.self, from: Fixture.members_ak_historical.data())
    #expect(alaska.items.map(\.bioguideId).contains("B001323"))
  }

  @Test("Omitted geographic limits accept only the observed default continuation")
  func omittedGeographicLimitsAcceptOnlyTheObservedDefaultContinuation() throws {
    let query = try MemberGeographyQuery(scope: .state(stateCode: "NY"))
    let first = try JSONDecoder().decode(
      MemberPage.self, from: Fixture.members_ny_default_first.data())
    let next = try JSONDecoder().decode(
      MemberPage.self, from: Fixture.members_ny_default_next.data())
    let endpoint = Endpoint.members(matching: query)
    let continuation = try CongressContinuation.next(after: first, endpoint: endpoint)
    let second = try #require(continuation)
    #expect(second.path == "/v3/member/NY?currentMember=false&offset=20&limit=20&format=json")
    let subsequent = try CongressContinuation.next(after: next, endpoint: second)
    #expect(subsequent?.path == "/v3/member/NY?currentMember=false&offset=40&limit=20&format=json")
    #expect(first.pagination.count == 179)
    #expect(next.pagination.count == 179)
  }
}
