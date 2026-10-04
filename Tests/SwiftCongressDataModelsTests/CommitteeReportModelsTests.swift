#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import SwiftCongressDataModels
import SwiftCongressDataTestSupport
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct CommitteeReportModelsTests {
  @Test("Committee report identities reject missing null and wrong scalar values")
  func committeeReportIdentitiesRejectMissingNullAndWrongScalarValues() throws {
    // Decoder-policy mutation, not additional provider evidence.
    let valid: [String: JSONValue] = [
      "congress": .number(109), "number": .number(519), "type": .string("FutureTYPE"),
    ]
    let report = try JSONDecoder().decode(
      CommitteeReportReference.self, from: JSONEncoder().encode(valid))
    #expect(report.number == 519)
    #expect(report.type == "FutureTYPE")
    for key in ["congress", "number", "type"] {
      for value: JSONValue? in [nil, .null, .boolean(true)] {
        var fields = valid
        fields[key] = value
        let bytes = try JSONEncoder().encode(fields)
        #expect(throws: DecodingError.self) {
          try JSONDecoder().decode(CommitteeReportReference.self, from: bytes)
        }
      }
    }
    var stringNumber = valid
    stringNumber["number"] = .string("519")
    let bytes = try JSONEncoder().encode(stringNumber)
    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode(CommitteeReportReference.self, from: bytes)
    }
  }

  @Test(
    "Committee report pages preserve exact source records and report parts",
    arguments: [
      Fixture.committee_house_hspw00_reports_chain_first,
      .committee_house_hspw00_reports_chain_terminal,
      .committee_house_hspw00_reports_first,
      .committee_house_hspw00_reports_window_first,
    ])
  func committeeReportPagesPreserveExactSourceRecordsAndReportParts(fixture: Fixture) throws {
    let bytes = try fixture.data()
    let page = try JSONDecoder().decode(CommitteeReportPage.self, from: bytes)
    #expect(page.items == page.reports)
    #expect(page.request == page.rawFields["request"])
    #expect(page.items.map(\.rawFields) == page.rawFields["reports"]?.array?.compactMap(\.object))
    #expect(
      try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(page))
        == JSONDecoder().decode(JSONValue.self, from: bytes))
    for report in page.items {
      #expect(report.chamber == report.rawFields["chamber"]?.string)
      #expect(report.citation == report.rawFields["citation"]?.string)
      #expect(report.congress == 109)
      #expect(report.number == report.rawFields["number"]?.integer)
      #expect(report.part == report.rawFields["part"]?.integer)
      #expect(report.type == "HRPT")
      #expect(report.updateDate == report.rawFields["updateDate"]?.string)
      #expect(report.url == report.rawFields["url"]?.string)
      #expect(report.rawFields["title"] == nil)
      #expect(
        try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(report))
          == .object(report.rawFields))
    }
    if fixture == .committee_house_hspw00_reports_chain_terminal {
      let part = try #require(page.items.first { $0.part == 2 })
      #expect(part.citation == "H. Rept. 109-519,Part 2")
      #expect(part.number == 519)
      #expect(part.url == "https://api.congress.gov/v3/committee-report/109/HRPT/519?format=json")
      #expect(part.updateDate == "2015-03-20 00:05:26+00:00")
      #expect(page.items.count == 12)
      #expect(page.pagination.next == nil)
    }
  }

  @Test("Committee report queries encode all chambers paging and source dates")
  func committeeReportQueriesEncodeAllChambersPagingAndSourceDates() throws {
    for chamber in CommitteeChamber.allCases {
      let identifier = try CommitteeIdentifier(chamber: chamber, code: "Future_A-1")
      let query = try CommitteeReportQuery(
        fromDateTime: "2015-03-20T00:04:12+00:00", limit: 250, offset: 12,
        toDateTime: "2015-03-20T00:06:53Z")
      let endpoint = Endpoint.committeeReports(for: identifier, matching: query)
      #expect(
        endpoint.path
          == "/v3/committee/\(chamber.rawValue)/Future_A-1/reports?format=json&fromDateTime=2015-03-20T00:04:12%2B00:00&limit=250&offset=12&toDateTime=2015-03-20T00:06:53Z"
      )
      #expect(
        CongressRequest.committeeReports(for: identifier, matching: query).resolution
          == .collection(endpoint))
      #expect(
        try Endpoint.committeeReports(for: identifier, matching: CommitteeReportQuery()).path
          == "/v3/committee/\(chamber.rawValue)/Future_A-1/reports?format=json&limit=20&offset=0")
    }
    #expect(throws: CongressInputError.invalidQuery) { try CommitteeReportQuery(limit: 0) }
    #expect(throws: CongressInputError.invalidQuery) { try CommitteeReportQuery(limit: 251) }
    #expect(throws: CongressInputError.invalidQuery) { try CommitteeReportQuery(offset: -1) }
  }

  @Test("Committee report sparse null unknown and duplicate fields round trip")
  func committeeReportSparseNullUnknownAndDuplicateFieldsRoundTrip() throws {
    // Decoder-policy mutation, not additional provider evidence.
    let bytes = Data(
      #"{"reports":[{"congress":109,"number":519,"type":"FutureTYPE","chamber":"Future chamber","part":null,"extra":null},{"congress":109,"number":519,"type":"FutureTYPE","chamber":"Future chamber","part":null,"extra":null}],"pagination":{"count":2},"request":null,"future":true}"#
        .utf8)
    let page = try JSONDecoder().decode(CommitteeReportPage.self, from: bytes)
    #expect(page.pagination.count == 2)
    #expect(page.items.count == 2)
    #expect(page.items[0] == page.items[1])
    #expect(page.items[0].chamber == "Future chamber")
    #expect(page.items[0].citation == nil)
    #expect(page.items[0].part == nil)
    #expect(page.items[0].rawFields["part"] == .null)
    #expect(page.items[0].rawFields["citation"] == nil)
    #expect(page.items[0].type == "FutureTYPE")
    #expect(page.items[0].updateDate == nil)
    #expect(page.items[0].url == nil)
    #expect(page.request == nil)
    #expect(
      try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(page))
        == JSONDecoder().decode(JSONValue.self, from: bytes))
  }
}
