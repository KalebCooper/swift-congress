#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import SwiftCongressDataModels
import SwiftCongressDataTestSupport
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct LawsModelsTests {
  @Test("Law citations preserve missing null unknown and duplicate source fields")
  func lawCitationsPreserveMissingNullUnknownAndDuplicateSourceFields() throws {
    // Labeled mutations test decoder policy, not additional provider observations.
    let detail = try JSONDecoder().decode(BillDetail.self, from: Fixture.law119_public1.data())
    var bill = detail.bill.rawFields
    let fields: [String: JSONValue] = [
      "number": .null, "type": .string("Future Law"), "unknown": .array([.null]),
    ]
    bill["laws"] = .array([.object(fields), .object(fields), .object([:])])
    let value = try JSONDecoder().decode(Bill.self, from: JSONEncoder().encode(bill))
    #expect(value.laws?.count == 3)
    #expect(value.laws?[0] == value.laws?[1])
    #expect(value.laws?[0].number == nil)
    #expect(value.laws?[0].type == "Future Law")
    #expect(value.laws?[0].rawFields["number"] == .null)
    #expect(value.laws?[2].rawFields["number"] == nil)
    #expect(value.laws?[2].type == nil)
    #expect(
      try JSONDecoder().decode([String: JSONValue].self, from: JSONEncoder().encode(value)) == bill)
    for null in [false, true] {
      if null { bill["laws"] = .null } else { bill.removeValue(forKey: "laws") }
      let missing = try JSONDecoder().decode(Bill.self, from: JSONEncoder().encode(bill))
      #expect(missing.laws == nil)
      #expect(missing.rawFields["laws"] == (null ? .null : nil))
      #expect(
        try JSONDecoder().decode([String: JSONValue].self, from: JSONEncoder().encode(missing))
          == bill)
    }
    for fields: [String: JSONValue] in [
      ["number": .number(1)], ["type": .number(1)],
    ] {
      #expect(throws: (any Error).self) {
        try JSONDecoder().decode(BillLawReference.self, from: JSONEncoder().encode(fields))
      }
    }
    let null = try JSONDecoder().decode(
      BillLawReference.self, from: Data(#"{"number":"raw citation","type":null}"#.utf8))
    #expect(null.number == "raw citation")
    #expect(null.type == nil)
    #expect(null.rawFields["type"] == .null)
  }

  @Test(
    "Law identifiers reject invalid decimal numbers",
    arguments: ["", "0", "000", "-1", "+1", "1.0", "1/2", "1?format=xml", "١", " 1", "1\n"])
  func lawIdentifiersRejectInvalidDecimalNumbers(number: String) {
    #expect(throws: CongressInputError.invalidLawIdentifier) {
      try LawIdentifier(congress: 119, number: number, type: .public)
    }
  }

  @Test("Law queries and identifiers retain route scope without bill identity rules")
  func lawQueriesAndIdentifiersRetainRouteScopeWithoutBillIdentityRules() throws {
    #expect(LawType.private.rawValue == "priv")
    #expect(LawType.public.rawValue == "pub")
    #expect(LawType(rawValue: "future") == nil)
    let historical = try LawIdentifier(congress: 1, number: "0001", type: .private)
    #expect(historical.congress == 1)
    #expect(historical.number == "0001")
    #expect(historical.type == .private)
    let detail = Endpoint.law(historical)
    #expect(detail.path == "/v3/law/1/priv/0001?format=json")
    #expect(CongressRequest.law(historical).resolution == .endpoint(detail))
    #expect(throws: CongressInputError.invalidLawIdentifier) {
      try LawIdentifier(congress: 0, number: "1", type: .public)
    }
    #expect(throws: CongressInputError.invalidLawIdentifier) {
      try LawIdentifier(congress: -1, number: "1", type: .private)
    }
    let all = try LawQuery(congress: 1)
    #expect(all.congress == 1)
    #expect(all.type == nil)
    #expect(all.page.limit == 20)
    #expect(Endpoint.laws(matching: all).path == "/v3/law/1?format=json&limit=20&offset=0")
    for type in [LawType.private, .public] {
      let query = try LawQuery(congress: 119, limit: 250, offset: 5, type: type)
      let endpoint = Endpoint.laws(matching: query)
      #expect(endpoint.path == "/v3/law/119/\(type.rawValue)?format=json&limit=250&offset=5")
      #expect(CongressRequest.laws(matching: query).resolution == .collection(endpoint))
      #expect(CongressRequest(endpoint: endpoint).resolution == .endpoint(endpoint))
    }
    #expect(throws: CongressInputError.invalidQuery) { try LawQuery(congress: 0) }
    #expect(throws: CongressInputError.invalidQuery) { try LawQuery(congress: -1) }
    #expect(throws: CongressInputError.invalidQuery) { try LawQuery(congress: 119, limit: 0) }
    #expect(throws: CongressInputError.invalidQuery) { try LawQuery(congress: 119, limit: 251) }
    #expect(throws: CongressInputError.invalidQuery) { try LawQuery(congress: 119, offset: -1) }
  }

  @Test("Law response envelopes round trip every recorded field")
  func lawResponseEnvelopesRoundTripEveryRecordedField() throws {
    for fixture in [
      Fixture.law117_private_first, .law117_private_next, .law117_private_terminal,
      .law119_inventory, .law119_public_inventory,
    ] {
      let bytes = try fixture.data()
      let original = try JSONDecoder().decode(JSONValue.self, from: bytes)
      let page = try JSONDecoder().decode(BillPage.self, from: bytes)
      #expect(
        try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(page)) == original)
      #expect(page.items.allSatisfy { $0.laws?.isEmpty == false })
    }
    for (fixture, billNumber, lawNumber, type) in [
      (Fixture.law119_public1, "5", "119-1", "Public Law"),
      (.law117_private1, "681", "117-1", "Private Law"),
      (.law93_public1, "1", "93-1", "Public Law"),
    ] {
      let bytes = try fixture.data()
      let original = try JSONDecoder().decode(JSONValue.self, from: bytes)
      let detail = try JSONDecoder().decode(BillDetail.self, from: bytes)
      #expect(
        try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(detail)) == original)
      #expect(detail.bill.number == billNumber)
      let citation = try #require(detail.bill.laws?.first)
      #expect(citation.number == lawNumber)
      #expect(citation.type == type)
      #expect(
        try JSONDecoder().decode([String: JSONValue].self, from: JSONEncoder().encode(citation))
          == citation.rawFields)
    }
  }

  @Test("Private law chain uses ordinary strict bill page continuation")
  func privateLawChainUsesOrdinaryStrictBillPageContinuation() throws {
    var endpoint = try Endpoint.laws(matching: LawQuery(congress: 117, limit: 1, type: .private))
    let fixtures: [Fixture] = [
      .law117_private_first, .law117_private_next, .law117_private_terminal,
    ]
    var citations: [String] = []
    for (index, fixture) in fixtures.enumerated() {
      let page = try JSONDecoder().decode(BillPage.self, from: fixture.data())
      #expect(page.pagination.count == 3)
      #expect(page.items.count == 1)
      citations += page.items.flatMap { $0.laws ?? [] }.compactMap(\.number)
      let next = try CongressContinuation.next(after: page, endpoint: endpoint)
      if index < 2 {
        endpoint = try #require(next)
        #expect(endpoint.path == "/v3/law/117/priv?offset=\(index + 1)&limit=1&format=json")
      } else {
        #expect(next == nil)
      }
    }
    #expect(citations == ["117-3", "117-1", "117-2"])
  }
}
