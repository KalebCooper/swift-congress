#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import SwiftCongressDataModels
import SwiftCongressDataTestSupport
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct CommitteeHouseCommunicationModelsTests {
  @Test("Committee House communication identities reject missing null and wrong scalar values")
  func committeeHouseCommunicationIdentitiesRejectMissingNullAndWrongScalarValues() throws {
    // Decoder-policy mutations, not additional provider evidence.
    let valid: [String: JSONValue] = [
      "communicationType": .object(["code": .string("Future")]),
      "congress": .number(119), "number": .number(7),
    ]
    let communication = try JSONDecoder().decode(
      CommitteeHouseCommunication.self, from: JSONEncoder().encode(valid))
    #expect(communication.communicationType.code == "Future")
    #expect(communication.communicationType.name == nil)
    #expect(communication.chamber == nil)
    #expect(communication.referralDate == nil)
    #expect(communication.updateDate == nil)
    #expect(communication.url == nil)
    for key in ["communicationType", "congress", "number"] {
      for value: JSONValue? in [nil, .null, .boolean(true), .string("7")] {
        var fields = valid
        fields[key] = value
        let bytes = try JSONEncoder().encode(fields)
        #expect(throws: DecodingError.self) {
          try JSONDecoder().decode(CommitteeHouseCommunication.self, from: bytes)
        }
      }
    }
    for value: JSONValue? in [nil, .null, .number(7), .boolean(true)] {
      var type: [String: JSONValue] = [:]
      type["code"] = value
      var fields = valid
      fields["communicationType"] = .object(type)
      let bytes = try JSONEncoder().encode(fields)
      #expect(throws: DecodingError.self) {
        try JSONDecoder().decode(CommitteeHouseCommunication.self, from: bytes)
      }
    }
  }

  @Test(
    "Committee House communication pages preserve exact types dates and records",
    arguments: [
      Fixture.committee_house_hsso00_house_communications_chain_first,
      .committee_house_hsso00_house_communications_chain_next,
      .committee_house_hsso00_house_communications_chain_terminal,
      .committee_house_hsso00_house_communications_first,
    ])
  func committeeHouseCommunicationPagesPreserveExactTypesDatesAndRecords(fixture: Fixture) throws {
    let bytes = try fixture.data()
    let page = try JSONDecoder().decode(CommitteeHouseCommunicationPage.self, from: bytes)
    #expect(page.items == page.houseCommunications)
    #expect(page.pagination.count == 15)
    #expect(page.request == page.rawFields["request"])
    #expect(
      page.items.map(\.rawFields)
        == page.rawFields["houseCommunications"]?.array?.compactMap(\.object))
    #expect(
      try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(page))
        == JSONDecoder().decode(JSONValue.self, from: bytes))
    for communication in page.items {
      #expect(communication.chamber == communication.rawFields["chamber"]?.string)
      #expect(communication.congress == communication.rawFields["congress"]?.integer)
      #expect(communication.number == communication.rawFields["number"]?.integer)
      #expect(communication.referralDate == communication.rawFields["referralDate"]?.string)
      #expect(communication.updateDate == communication.rawFields["updateDate"]?.string)
      #expect(communication.url == communication.rawFields["url"]?.string)
      let type = communication.communicationType
      #expect(type.code == type.rawFields["code"]?.string)
      #expect(type.name == type.rawFields["name"]?.string)
      #expect(
        try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(type))
          == communication.rawFields["communicationType"])
      #expect(
        try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(communication))
          == .object(communication.rawFields))
    }
    if fixture == .committee_house_hsso00_house_communications_chain_first {
      #expect(page.items.first?.communicationType.code == "EC")
      #expect(page.items.first?.communicationType.name == "Executive Communication")
      #expect(page.items.last?.communicationType.code == "PT")
      #expect(page.items.last?.communicationType.name == "Petition")
      #expect(page.items.first?.referralDate == "2015-07-07")
      #expect(page.items.first?.updateDate == "2018-02-02")
    }
    if fixture == .committee_house_hsso00_house_communications_chain_terminal {
      #expect(page.items.count == 5)
      #expect(page.pagination.next == nil)
    }
  }

  @Test("Committee House communication requests use only House paging and safe source codes")
  func committeeHouseCommunicationRequestsUseOnlyHousePagingAndSafeSourceCodes() throws {
    let identifier = try CommitteeIdentifier(chamber: .house, code: "Future_A-1")
    let page = try CongressQuery(limit: 250, offset: 5)
    let endpoint = try Endpoint.committeeHouseCommunications(for: identifier, page: page)
    #expect(
      endpoint.path
        == "/v3/committee/house/Future_A-1/house-communication?format=json&limit=250&offset=5")
    let stored = try CongressRequest.committeeHouseCommunications(for: identifier, page: page)
    #expect(stored.resolution == .collection(endpoint))
    #expect(
      try Endpoint.committeeHouseCommunications(for: identifier).path
        == "/v3/committee/house/Future_A-1/house-communication?format=json&limit=20&offset=0")
    #expect(throws: CongressInputError.invalidQuery) { try CongressQuery(limit: 0) }
    #expect(throws: CongressInputError.invalidQuery) { try CongressQuery(limit: 251) }
    #expect(throws: CongressInputError.invalidQuery) { try CongressQuery(limit: 1, offset: -1) }
  }

  @Test("Committee House communication sparse null unknown and duplicate fields round trip")
  func committeeHouseCommunicationSparseNullUnknownAndDuplicateFieldsRoundTrip() throws {
    // Decoder-policy mutations, not additional provider evidence.
    let record: [String: JSONValue] = [
      "chamber": .null,
      "communicationType": .object([
        "code": .string("Future"), "name": .null, "future": .string("value"),
        "referralDate": .string("nested-is-not-an-alias"),
      ]),
      "congress": .number(119), "number": .number(7), "referralDate": .null,
      "updateDate": .string("raw date"), "extra": .null,
    ]
    let fields: [String: JSONValue] = [
      "houseCommunications": .array([.object(record), .object(record)]),
      "pagination": .object(["count": .number(2)]), "request": .null, "future": .boolean(true),
    ]
    let bytes = try JSONEncoder().encode(fields)
    let page = try JSONDecoder().decode(CommitteeHouseCommunicationPage.self, from: bytes)
    #expect(page.items.count == 2)
    #expect(page.items[0] == page.items[1])
    #expect(page.items[0].communicationType.code == "Future")
    #expect(page.items[0].communicationType.name == nil)
    #expect(page.items[0].communicationType.rawFields["name"] == .null)
    #expect(page.items[0].chamber == nil)
    #expect(page.items[0].rawFields["chamber"] == .null)
    #expect(page.items[0].referralDate == nil)
    #expect(page.items[0].updateDate == "raw date")
    #expect(page.items[0].rawFields["url"] == nil)
    #expect(page.request == nil)
    #expect(
      try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(page)) == .object(fields))
  }
}
