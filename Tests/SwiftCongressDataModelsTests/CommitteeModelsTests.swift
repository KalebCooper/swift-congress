#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import SwiftCongressDataModels
import SwiftCongressDataTestSupport
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct CommitteeModelsTests {
  @Test(
    "Committee details retain ordered history explicit relationships and exact raw fields",
    arguments: [
      Fixture.committee_118_house_hspw00, .committee_house_hspw00, .committee_house_hspw14,
      .committee_joint_jcov00, .committee_senate_ssju00,
    ])
  func committeeDetailsRetainOrderedHistoryExplicitRelationshipsAndExactRawFields(fixture: Fixture)
    throws
  {
    let bytes = try fixture.data()
    let detail = try JSONDecoder().decode(CommitteeDetail.self, from: bytes)
    #expect(
      try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(detail))
        == JSONDecoder().decode(JSONValue.self, from: bytes))
    let profile = detail.committee
    #expect(profile.rawFields["name"] == nil)
    #expect(profile.rawFields["chamber"] == nil)
    let history = try #require(profile.history)
    #expect(history.map(\.rawFields) == profile.rawFields["history"]?.array?.compactMap(\.object))
    #expect(history.first?.officialName != nil)
    switch profile.systemCode {
    case "hspw00":
      #expect(profile.isCurrent == true)
      #expect(
        history.map(\.startDate) == [
          "1995-01-04T05:00:00Z", "1975-01-01T05:00:00Z", "1946-08-02T04:00:00Z",
        ])
      #expect(history[0].naraId == "10533201")
      #expect(history[0].superintendentDocumentNumber == "Y 4.T 68/2:")
      #expect(history[1].endDate == "1995-01-03T05:00:00Z")
      #expect(profile.subcommittees?.count == 15)
      #expect(profile.parent == nil)
      let scoped = fixture == .committee_118_house_hspw00
      #expect(profile.bills?.count == (scoped ? 913 : 27742))
      #expect(profile.communications?.count == (scoped ? 1663 : 9644))
      #expect(profile.reports?.count == (scoped ? 86 : 931))
      #expect(profile.bills?.url?.contains("/committee/118/") == scoped)
      #expect(profile.subcommittees?.first?.url?.contains("/committee/118/") == scoped)
    case "hspw14":
      #expect(profile.parent?.systemCode == "hspw00")
      #expect(profile.parent?.name == "Transportation and Infrastructure Committee")
      #expect(profile.subcommittees == nil)
      #expect(profile.reports == nil)
      #expect(profile.communications?.count == 0)
      #expect(history[1].committeeTypeCode == nil)
    case "jcov00":
      #expect(profile.isCurrent == false)
      #expect(history[0].endDate == "2023-07-01T03:59:00Z")
      #expect(profile.bills == nil)
      #expect(profile.committeeWebsiteUrl == nil)
      #expect(profile.communications == nil)
      #expect(profile.nominations == nil)
      #expect(profile.reports == nil)
    case "ssju00":
      #expect(history[0].startDate == "1816-12-10T04:56:00Z")
      #expect(profile.nominations?.count == 5583)
      #expect(profile.subcommittees?.count == 24)
    default: Issue.record("Unexpected fixture identity")
    }
  }

  @Test("Committee identifiers preserve safe codes and validate detail scope separately")
  func committeeIdentifiersPreserveSafeCodesAndValidateDetailScopeSeparately() throws {
    for chamber in CommitteeChamber.allCases {
      for code in ["hspw00", "Future-01_a", String(repeating: "x", count: 100)] {
        let identifier = try CommitteeIdentifier(chamber: chamber, code: code)
        #expect(identifier.code == code)
        let global = try Endpoint.committee(identifier)
        let scoped = try Endpoint.committee(identifier, congress: 118)
        #expect(global.path == "/v3/committee/\(chamber.rawValue)/\(code)?format=json")
        #expect(scoped.path == "/v3/committee/118/\(chamber.rawValue)/\(code)?format=json")
        #expect(try CongressRequest.committee(identifier).resolution == .endpoint(global))
        #expect(
          try CongressRequest.committee(identifier, congress: 118).resolution == .endpoint(scoped))
        #expect(throws: CongressInputError.invalidQuery) {
          try Endpoint.committee(identifier, congress: 0)
        }
        #expect(throws: CongressInputError.invalidQuery) {
          try CongressRequest.committee(identifier, congress: -1)
        }
      }
    }
    for code in ["", ".", "..", "a/b", "a%2Fb", "a?b", "a#b", " a", "é", "a\n"] {
      #expect(throws: CongressInputError.invalidCommitteeIdentifier) {
        try CommitteeIdentifier(chamber: .house, code: code)
      }
    }
  }

  @Test(
    "Committee inventories preserve all raw records and explicit references",
    arguments: [
      Fixture.committee_directory_all_first, .committee_directory_congress_119,
      .committee_directory_congress_119_joint_chain_first,
      .committee_directory_congress_119_joint_chain_terminal,
      .committee_directory_congress_119_joint_first, .committee_directory_joint,
    ])
  func committeeInventoriesPreserveAllRawRecordsAndExplicitReferences(fixture: Fixture) throws {
    let bytes = try fixture.data()
    let page = try JSONDecoder().decode(CommitteePage.self, from: bytes)
    #expect(page.items == page.committees)
    #expect(
      try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(page))
        == JSONDecoder().decode(JSONValue.self, from: bytes))
    for committee in page.items {
      #expect(committee.chamber == committee.rawFields["chamber"]?.string)
      #expect(committee.committeeTypeCode == committee.rawFields["committeeTypeCode"]?.string)
      #expect(committee.parent?.rawFields == committee.rawFields["parent"]?.object)
      #expect(
        committee.subcommittees?.map(\.rawFields)
          == committee.rawFields["subcommittees"]?.array?.compactMap(\.object))
    }
    if fixture == .committee_directory_joint {
      #expect(page.items.contains { $0.parent != nil })
    }
    if fixture == .committee_directory_congress_119 {
      #expect(page.items.count == 236)
      #expect(page.pagination.count == 238)
      #expect(page.pagination.next == nil)
    }
  }

  @Test("Committee queries encode four scopes with paging and source dates")
  func committeeQueriesEncodeFourScopesWithPagingAndSourceDates() throws {
    let scopes: [(CommitteeQuery.Scope, String)] = [
      (.all, ""), (.chamber(.joint), "/joint"), (.congress(119), "/119"),
      (.congressChamber(chamber: .house, congress: 118), "/118/house"),
    ]
    for (scope, suffix) in scopes {
      let query = try CommitteeQuery(
        fromDateTime: "2026-01-01T00:00:00+00:00", limit: 250, offset: 5,
        scope: scope, toDateTime: "2026-02-01T00:00:00Z")
      let endpoint = Endpoint.committees(matching: query)
      #expect(
        endpoint.path
          == "/v3/committee\(suffix)?format=json&fromDateTime=2026-01-01T00:00:00%2B00:00&limit=250&offset=5&toDateTime=2026-02-01T00:00:00Z"
      )
      #expect(CongressRequest.committees(matching: query).resolution == .collection(endpoint))
    }
    #expect(
      try Endpoint.committees(matching: CommitteeQuery()).path
        == "/v3/committee?format=json&limit=20&offset=0")
    #expect(throws: CongressInputError.invalidQuery) { try CommitteeQuery(limit: 0) }
    #expect(throws: CongressInputError.invalidQuery) { try CommitteeQuery(limit: 251) }
    #expect(throws: CongressInputError.invalidQuery) { try CommitteeQuery(offset: -1) }
    #expect(throws: CongressInputError.invalidQuery) { try CommitteeQuery(scope: .congress(0)) }
    #expect(throws: CongressInputError.invalidQuery) {
      try CommitteeQuery(scope: .congressChamber(chamber: .joint, congress: -1))
    }
  }

  @Test("Committee sparse unknown and null fields retain source semantics")
  func committeeSparseUnknownAndNullFieldsRetainSourceSemantics() throws {
    // Decoder-policy mutations, not additional provider evidence.
    let bytes = Data(
      #"{"systemCode":"future","chamber":"FutureChamber","committeeTypeCode":"FutureType","type":"FutureProfileType","name":null,"history":[{"officialName":null,"future":true}],"extra":null}"#
        .utf8)
    let profile = try JSONDecoder().decode(CommitteeProfile.self, from: bytes)
    let summary = try JSONDecoder().decode(CommitteeSummary.self, from: bytes)
    #expect(profile.isCurrent == nil)
    #expect(profile.type == "FutureProfileType")
    #expect(profile.history?.first?.officialName == nil)
    #expect(summary.chamber == "FutureChamber")
    #expect(summary.committeeTypeCode == "FutureType")
    #expect(summary.name == nil)
    #expect(summary.rawFields["name"] == .null)
    #expect(
      try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(profile))
        == JSONDecoder().decode(JSONValue.self, from: bytes))
    var fields = profile.rawFields
    fields.removeValue(forKey: "systemCode")
    let missing = try JSONEncoder().encode(fields)
    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode(CommitteeProfile.self, from: missing)
    }
    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode(CommitteeSummary.self, from: missing)
    }
  }
}
