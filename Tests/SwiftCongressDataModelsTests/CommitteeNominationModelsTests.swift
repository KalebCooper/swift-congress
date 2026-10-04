#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import SwiftCongressDataModels
import SwiftCongressDataTestSupport
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct CommitteeNominationModelsTests {
  @Test("Committee nomination identities reject missing null and wrong scalar values")
  func committeeNominationIdentitiesRejectMissingNullAndWrongScalarValues() throws {
    // Decoder-policy mutations, not additional provider evidence.
    let valid: [String: JSONValue] = [
      "congress": .number(118), "number": .number(1983), "partNumber": .string("00"),
    ]
    let nomination = try JSONDecoder().decode(
      CommitteeNomination.self, from: JSONEncoder().encode(valid))
    #expect(nomination.partNumber == "00")
    for key in ["congress", "number", "partNumber"] {
      for value: JSONValue? in [nil, .null, .boolean(true)] {
        var fields = valid
        fields[key] = value
        let bytes = try JSONEncoder().encode(fields)
        #expect(throws: DecodingError.self) {
          try JSONDecoder().decode(CommitteeNomination.self, from: bytes)
        }
      }
    }
    for (key, value) in [("number", JSONValue.string("1983")), ("partNumber", .number(0))] {
      var fields = valid
      fields[key] = value
      let bytes = try JSONEncoder().encode(fields)
      #expect(throws: DecodingError.self) {
        try JSONDecoder().decode(CommitteeNomination.self, from: bytes)
      }
    }
  }

  @Test(
    "Committee nomination pages preserve exact records actions flags and parts",
    arguments: [
      Fixture.committee_senate_slia00_nominations_chain_first,
      .committee_senate_slia00_nominations_chain_next,
      .committee_senate_slia00_nominations_chain_terminal,
      .committee_senate_slia00_nominations_first,
    ])
  func committeeNominationPagesPreserveExactRecordsActionsFlagsAndParts(fixture: Fixture) throws {
    let bytes = try fixture.data()
    let page = try JSONDecoder().decode(CommitteeNominationPage.self, from: bytes)
    #expect(page.items == page.nominations)
    #expect(page.pagination.count == 96)
    #expect(page.request == page.rawFields["request"])
    #expect(
      page.items.map(\.rawFields) == page.rawFields["nominations"]?.array?.compactMap(\.object))
    #expect(
      try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(page))
        == JSONDecoder().decode(JSONValue.self, from: bytes))
    for nomination in page.items {
      #expect(nomination.citation == nomination.rawFields["citation"]?.string)
      #expect(nomination.congress == nomination.rawFields["congress"]?.integer)
      #expect(nomination.description == nomination.rawFields["description"]?.string)
      #expect(nomination.number == nomination.rawFields["number"]?.integer)
      #expect(nomination.partNumber == nomination.rawFields["partNumber"]?.string)
      #expect(nomination.receivedDate == nomination.rawFields["receivedDate"]?.string)
      #expect(nomination.updateDate == nomination.rawFields["updateDate"]?.string)
      #expect(nomination.url == nomination.rawFields["url"]?.string)
      let action = try #require(nomination.latestAction)
      #expect(action.actionDate == action.rawFields["actionDate"]?.string)
      #expect(action.text == action.rawFields["text"]?.string)
      #expect(
        try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(action))
          == nomination.rawFields["latestAction"])
      let type = try #require(nomination.nominationType)
      #expect(type.isCivilian == true)
      #expect(type.isMilitary == false)
      #expect(
        try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(type))
          == nomination.rawFields["nominationType"])
      #expect(
        try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(nomination))
          == .object(nomination.rawFields))
    }
    if fixture == .committee_senate_slia00_nominations_chain_first {
      let zeroPart = try #require(page.items.first { $0.number == 1983 })
      #expect(zeroPart.partNumber == "00")
      #expect(zeroPart.url == "https://api.congress.gov/v3/nomination/118/1983?format=json")
    }
    if fixture == .committee_senate_slia00_nominations_chain_next {
      #expect(page.items.contains { $0.partNumber == "09" })
    }
    if fixture == .committee_senate_slia00_nominations_chain_terminal {
      #expect(page.items.count == 32)
      #expect(page.pagination.next == nil)
    }
  }

  @Test("Committee nomination requests use only Senate paging and safe source codes")
  func committeeNominationRequestsUseOnlySenatePagingAndSafeSourceCodes() throws {
    let identifier = try CommitteeIdentifier(chamber: .senate, code: "Future_A-1")
    let page = try CongressQuery(limit: 250, offset: 32)
    let endpoint = try Endpoint.committeeNominations(for: identifier, page: page)
    #expect(
      endpoint.path == "/v3/committee/senate/Future_A-1/nominations?format=json&limit=250&offset=32"
    )
    let stored = try CongressRequest.committeeNominations(for: identifier, page: page)
    #expect(stored.resolution == .collection(endpoint))
    #expect(
      try Endpoint.committeeNominations(for: identifier).path
        == "/v3/committee/senate/Future_A-1/nominations?format=json&limit=20&offset=0")
    #expect(throws: CongressInputError.invalidQuery) { try CongressQuery(limit: 0) }
    #expect(throws: CongressInputError.invalidQuery) { try CongressQuery(limit: 251) }
    #expect(throws: CongressInputError.invalidQuery) { try CongressQuery(limit: 1, offset: -1) }
  }

  @Test("Committee nomination sparse null unknown and duplicate fields round trip")
  func committeeNominationSparseNullUnknownAndDuplicateFieldsRoundTrip() throws {
    // Decoder-policy mutations, not additional provider evidence.
    let record: [String: JSONValue] = [
      "citation": .null, "congress": .number(119), "description": .null,
      "latestAction": .object([
        "actionDate": .null, "text": .string("Future action"), "extra": .null,
      ]),
      "nominationType": .object([
        "isCivilian": .null, "isMilitary": .boolean(true), "inMilitary": .boolean(false),
        "future": .string("value"),
      ]),
      "number": .number(7), "partNumber": .string("09"), "receivedDate": .null,
    ]
    let fields: [String: JSONValue] = [
      "nominations": .array([.object(record), .object(record)]),
      "pagination": .object(["count": .number(2)]), "request": .null, "future": .boolean(true),
    ]
    let bytes = try JSONEncoder().encode(fields)
    let page = try JSONDecoder().decode(CommitteeNominationPage.self, from: bytes)
    #expect(page.items.count == 2)
    #expect(page.items[0] == page.items[1])
    #expect(page.items[0].partNumber == "09")
    #expect(page.items[0].citation == nil)
    #expect(page.items[0].rawFields["citation"] == .null)
    #expect(page.items[0].rawFields["url"] == nil)
    #expect(page.items[0].latestAction?.actionDate == nil)
    #expect(page.items[0].latestAction?.text == "Future action")
    #expect(page.items[0].nominationType?.isCivilian == nil)
    #expect(page.items[0].nominationType?.isMilitary == true)
    #expect(page.request == nil)
    #expect(
      try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(page)) == .object(fields))
    for value: JSONValue? in [nil, .null] {
      var sparse = record
      sparse["latestAction"] = value
      sparse["nominationType"] = value
      let nomination = try JSONDecoder().decode(
        CommitteeNomination.self, from: JSONEncoder().encode(sparse))
      #expect(nomination.latestAction == nil)
      #expect(nomination.nominationType == nil)
      #expect(
        try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(nomination))
          == .object(sparse))
    }
    let alias = try JSONDecoder().decode(
      CommitteeNominationType.self,
      from: JSONEncoder().encode(["inMilitary": JSONValue.boolean(true)]))
    #expect(alias.isMilitary == nil)
  }
}
