#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import SwiftCongressDataModels
import SwiftCongressDataTestSupport
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct CommitteeBillModelsTests {
  @Test("Committee bill identities reject missing null and wrong scalar values")
  func committeeBillIdentitiesRejectMissingNullAndWrongScalarValues() throws {
    let valid: [String: JSONValue] = [
      "congress": .number(110), "number": .string("001"), "type": .string("FutureTYPE"),
    ]
    let bill = try JSONDecoder().decode(CommitteeBill.self, from: JSONEncoder().encode(valid))
    #expect(bill.number == "001")
    #expect(bill.type.rawValue == "FutureTYPE")
    for key in ["congress", "number", "type"] {
      for value: JSONValue? in [nil, .null, .boolean(true)] {
        var fields = valid
        fields[key] = value
        let bytes = try JSONEncoder().encode(fields)
        #expect(throws: DecodingError.self) {
          try JSONDecoder().decode(CommitteeBill.self, from: bytes)
        }
      }
    }
  }

  @Test(
    "Committee bill pages preserve nested metadata and exact source records",
    arguments: [
      Fixture.committee_house_hspw00_bills_chain_first,
      .committee_house_hspw00_bills_chain_terminal,
      .committee_house_hspw00_bills_first,
      .committee_house_hspw00_bills_window_first,
    ])
  func committeeBillPagesPreserveNestedMetadataAndExactSourceRecords(fixture: Fixture) throws {
    let bytes = try fixture.data()
    let page = try JSONDecoder().decode(CommitteeBillPage.self, from: bytes)
    let resource = try #require(page.rawFields["committee-bills"]?.object)
    #expect(page.items == page.bills)
    #expect(page.count == resource["count"]?.integer)
    #expect(page.url == resource["url"]?.string)
    #expect(page.request == page.rawFields["request"])
    #expect(page.items.map(\.rawFields) == resource["bills"]?.array?.compactMap(\.object))
    #expect(
      try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(page))
        == JSONDecoder().decode(JSONValue.self, from: bytes))
    for bill in page.items {
      #expect(bill.actionDate == bill.rawFields["actionDate"]?.string)
      #expect(bill.congress == 110)
      #expect(bill.number == bill.rawFields["number"]?.string)
      #expect(bill.rawFields["title"] == nil)
      #expect(bill.relationshipType == bill.rawFields["relationshipType"]?.string)
      #expect(bill.type.rawValue == bill.rawFields["type"]?.string)
      #expect(bill.updateDate == bill.rawFields["updateDate"]?.string)
      #expect(bill.url == bill.rawFields["url"]?.string)
    }
    if fixture == .committee_house_hspw00_bills_chain_terminal {
      #expect(page.items.last?.type.rawValue == "S")
      #expect(
        page.items.contains { $0.relationshipType == "Bills of Interest - Exchange of Letters" })
      #expect(page.items.count == 49)
      #expect(page.pagination.next == nil)
    }
  }

  @Test("Committee bill queries encode all chambers paging and source dates")
  func committeeBillQueriesEncodeAllChambersPagingAndSourceDates() throws {
    for chamber in CommitteeChamber.allCases {
      let identifier = try CommitteeIdentifier(chamber: chamber, code: "Future_A-1")
      let query = try CommitteeBillQuery(
        fromDateTime: "2015-12-07T16:53:38+00:00", limit: 250, offset: 60,
        toDateTime: "2015-12-07T16:53:40Z")
      let endpoint = Endpoint.committeeBills(for: identifier, matching: query)
      #expect(
        endpoint.path
          == "/v3/committee/\(chamber.rawValue)/Future_A-1/bills?format=json&fromDateTime=2015-12-07T16:53:38%2B00:00&limit=250&offset=60&toDateTime=2015-12-07T16:53:40Z"
      )
      #expect(
        CongressRequest.committeeBills(for: identifier, matching: query).resolution
          == .collection(endpoint))
      #expect(
        try Endpoint.committeeBills(for: identifier, matching: CommitteeBillQuery()).path
          == "/v3/committee/\(chamber.rawValue)/Future_A-1/bills?format=json&limit=20&offset=0")
    }
    #expect(throws: CongressInputError.invalidQuery) { try CommitteeBillQuery(limit: 0) }
    #expect(throws: CongressInputError.invalidQuery) { try CommitteeBillQuery(limit: 251) }
    #expect(throws: CongressInputError.invalidQuery) { try CommitteeBillQuery(offset: -1) }
  }

  @Test("Committee bill sparse null unknown and duplicate fields round trip")
  func committeeBillSparseNullUnknownAndDuplicateFieldsRoundTrip() throws {
    // Decoder-policy mutation, not additional provider evidence.
    let bytes = Data(
      #"{"committee-bills":{"bills":[{"congress":110,"number":"001","type":"FutureTYPE","actionDate":null,"relationshipType":"Future relation","extra":null},{"congress":110,"number":"001","type":"FutureTYPE","actionDate":null,"relationshipType":"Future relation","extra":null}],"count":7,"url":"source-link","future":{"null":null}},"pagination":{"count":2},"request":null,"future":true}"#
        .utf8)
    let page = try JSONDecoder().decode(CommitteeBillPage.self, from: bytes)
    #expect(page.count == 7)
    #expect(page.pagination.count == 2)
    #expect(page.url == "source-link")
    #expect(page.items.count == 2)
    #expect(page.items[0] == page.items[1])
    #expect(page.items[0].actionDate == nil)
    #expect(page.items[0].rawFields["actionDate"] == .null)
    #expect(page.items[0].updateDate == nil)
    #expect(page.items[0].url == nil)
    #expect(page.request == nil)
    #expect(
      try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(page))
        == JSONDecoder().decode(JSONValue.self, from: bytes))
  }
}
