#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import SwiftCongressDataModels
import SwiftCongressDataTestSupport
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct MemberLegislationModelsTests {
  @Test("Empty member legislation envelopes retain metadata and require their arrays")
  func emptyMemberLegislationEnvelopesRetainMetadataAndRequireTheirArrays() throws {
    // Labeled mutations establish decoder behavior, not a captured empty inventory.
    for cosponsored in [false, true] {
      let fixture: Fixture =
        cosponsored
        ? .member_c001136_cosponsored_legislation_first
        : .member_c001136_sponsored_legislation_first
      let key = cosponsored ? "cosponsoredLegislation" : "sponsoredLegislation"
      var fields = try JSONDecoder().decode([String: JSONValue].self, from: fixture.data())
      fields[key] = .array([])
      fields["pagination"] = .object(["count": .number(0)])
      fields["request"] = .null
      let bytes = try JSONEncoder().encode(fields)
      if cosponsored {
        let page = try JSONDecoder().decode(CosponsoredLegislationPage.self, from: bytes)
        #expect(page.items.isEmpty)
        #expect(page.request == nil)
        #expect(page.rawFields["request"] == .null)
      } else {
        let page = try JSONDecoder().decode(SponsoredLegislationPage.self, from: bytes)
        #expect(page.items.isEmpty)
        #expect(page.request == nil)
        #expect(page.rawFields["request"] == .null)
      }
      fields.removeValue(forKey: key)
      let missing = try JSONEncoder().encode(fields)
      if cosponsored {
        #expect(throws: (any Error).self) {
          try JSONDecoder().decode(CosponsoredLegislationPage.self, from: missing)
        }
      } else {
        #expect(throws: (any Error).self) {
          try JSONDecoder().decode(SponsoredLegislationPage.self, from: missing)
        }
      }
    }
  }

  @Test("Former member amendment rows retain missing bill fields")
  func formerMemberAmendmentRowsRetainMissingBillFields() throws {
    let cosponsored = try JSONDecoder().decode(
      CosponsoredLegislationPage.self,
      from: Fixture.member_l000174_cosponsored_legislation_discovery.data())
    let sponsored = try JSONDecoder().decode(
      SponsoredLegislationPage.self,
      from: Fixture.member_l000174_sponsored_legislation_discovery.data())
    #expect(cosponsored.items.first?.amendmentNumber == "5164")
    #expect(sponsored.items.first?.amendmentNumber == "5136")
    for row in cosponsored.items + sponsored.items {
      #expect(row.congress == 114)
      #expect(row.type == nil)
      #expect(row.number == nil)
      #expect(row.title == nil)
      #expect(row.latestAction == nil)
      #expect(row.policyArea == nil)
      #expect(row.rawFields["type"] == .null)
      #expect(row.rawFields["number"] == nil)
      #expect(row.url?.contains("/amendment/114/samdt/") == true)
    }
    #expect(cosponsored.request?.object?["bioguideId"] == .string("l000174"))
  }

  @Test("Member legislation mutations retain null empty unknown and malformed values")
  func memberLegislationMutationsRetainNullEmptyUnknownAndMalformedValues() throws {
    // Labeled mutation of an official bill row, not additional provider evidence.
    let page = try JSONDecoder().decode(
      SponsoredLegislationPage.self,
      from: Fixture.member_c001136_sponsored_legislation_first.data())
    var fields = try #require(page.items.first?.rawFields)
    fields["introducedDate"] = .null
    fields["number"] = .string("0001")
    fields["policyArea"] = .object(["name": .null, "future": .boolean(true)])
    fields["title"] = .string("")
    fields["type"] = .string("FUTURE")
    fields["unknown"] = .array([.null])
    fields.removeValue(forKey: "url")
    let row = try JSONDecoder().decode(MemberLegislation.self, from: JSONEncoder().encode(fields))
    #expect(row.introducedDate == nil)
    #expect(row.number == "0001")
    #expect(row.policyArea?.object?["name"] == .null)
    #expect(row.title == "")
    #expect(row.type == "FUTURE")
    #expect(row.url == nil)
    #expect(
      try JSONDecoder().decode(
        [String: JSONValue].self,
        from: JSONEncoder().encode(row)) == fields)
    fields["number"] = .number(1)
    #expect(throws: (any Error).self) {
      try JSONDecoder().decode(MemberLegislation.self, from: JSONEncoder().encode(fields))
    }
    fields.removeValue(forKey: "number")
    fields.removeValue(forKey: "congress")
    #expect(throws: (any Error).self) {
      try JSONDecoder().decode(MemberLegislation.self, from: JSONEncoder().encode(fields))
    }
  }

  @Test(
    "Member legislation pages round trip every recorded source field",
    arguments: [
      Fixture.member_c001136_cosponsored_legislation_discovery,
      Fixture.member_c001136_cosponsored_legislation_first,
      Fixture.member_c001136_cosponsored_legislation_next,
      Fixture.member_c001136_cosponsored_legislation_terminal,
      Fixture.member_c001136_sponsored_legislation_discovery,
      Fixture.member_c001136_sponsored_legislation_first,
      Fixture.member_c001136_sponsored_legislation_next,
      Fixture.member_c001136_sponsored_legislation_terminal,
      Fixture.member_l000174_cosponsored_legislation_discovery,
      Fixture.member_l000174_sponsored_legislation_discovery,
    ])
  func memberLegislationPagesRoundTripEveryRecordedSourceField(fixture: Fixture) throws {
    let bytes = try fixture.data()
    let encoded: Data
    let rows: [MemberLegislation]
    if fixture.rawValue.contains("-cosponsored-") {
      let page = try JSONDecoder().decode(CosponsoredLegislationPage.self, from: bytes)
      #expect(page.items == page.cosponsoredLegislation)
      encoded = try JSONEncoder().encode(page)
      rows = page.items
    } else {
      let page = try JSONDecoder().decode(SponsoredLegislationPage.self, from: bytes)
      #expect(page.items == page.sponsoredLegislation)
      encoded = try JSONEncoder().encode(page)
      rows = page.items
    }
    for row in rows where row.rawFields["number"] != nil {
      let introducedDate = try #require(row.rawFields["introducedDate"]?.string)
      let latestAction = try #require(row.rawFields["latestAction"]?.object)
      let title = try #require(row.rawFields["title"]?.string)
      #expect(row.introducedDate == introducedDate)
      #expect(row.latestAction?.actionDate == latestAction["actionDate"]?.string)
      #expect(row.latestAction?.text == latestAction["text"]?.string)
      #expect(row.title == title)
    }
    #expect(
      try JSONDecoder().decode(JSONValue.self, from: encoded)
        == JSONDecoder().decode(JSONValue.self, from: bytes))
  }

  @Test("Member legislation requests preserve exact member paths and bounded queries")
  func memberLegislationRequestsPreserveExactMemberPathsAndBoundedQueries() throws {
    let member = try MemberIdentifier(rawValue: "aBc_1-2")
    #expect(
      Endpoint.cosponsoredLegislation(for: member).path
        == "/v3/member/aBc_1-2/cosponsored-legislation?format=json&limit=20&offset=0")
    #expect(
      Endpoint.sponsoredLegislation(for: member, page: try CongressQuery(limit: 250, offset: 10))
        .path
        == "/v3/member/aBc_1-2/sponsored-legislation?format=json&limit=250&offset=10")
    #expect(throws: CongressInputError.invalidMemberIdentifier) {
      try MemberIdentifier(rawValue: "../member")
    }
    #expect(throws: CongressInputError.invalidMemberIdentifier) {
      try MemberIdentifier(rawValue: "A%2F")
    }
    #expect(throws: CongressInputError.invalidQuery) { try CongressQuery(limit: 0) }
    #expect(throws: CongressInputError.invalidQuery) { try CongressQuery(limit: 251) }
    #expect(throws: CongressInputError.invalidQuery) { try CongressQuery(limit: 20, offset: -1) }
    #expect(
      CongressRequest.cosponsoredLegislation(for: member).resolution
        == .collection(.cosponsoredLegislation(for: member)))
    #expect(
      CongressRequest.sponsoredLegislation(for: member).resolution
        == .collection(.sponsoredLegislation(for: member)))
  }
}
