#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import SwiftCongressDataModels
import SwiftCongressDataTestSupport
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct CommitteeReportInventoryModelsTests {
  @Test("Report detail preserves ordered parts and separate bill and treaty identities")
  func reportDetailPreservesOrderedPartsAndSeparateBillAndTreatyIdentities() throws {
    let house = try JSONDecoder().decode(
      CommitteeReportDetail.self,
      from: Fixture.committee_report_109_hrpt_519_detail.data())
    #expect(house.committeeReports.map(\.part) == [1, 2])
    #expect(
      house.committeeReports.map(\.citation) == [
        "H. Rept. 109-519,Part 1", "H. Rept. 109-519,Part 2",
      ])
    #expect(
      house.committeeReports.map { $0.committees?.first?.systemCode } == ["hsgo00", "hspw00"])
    #expect(
      house.committeeReports.allSatisfy {
        $0.number == 519 && $0.congress == 109 && $0.isConferenceReport == false
      })
    #expect(house.committeeReports.first?.associatedBill?.first?.number == "5316")
    #expect(house.committeeReports.first?.text?.count == 4)
    let executive = try JSONDecoder().decode(
      CommitteeReportDetail.self,
      from: Fixture.committee_report_117_erpt_5_detail.data())
    #expect(executive.committeeReports.first?.associatedTreaties?.first?.number == 3)
    #expect(executive.committeeReports.first?.associatedTreaties?.first?.part == nil)
    #expect(executive.committeeReports.first?.associatedBill == nil)
    let senate = try JSONDecoder().decode(
      CommitteeReportDetail.self,
      from: Fixture.committee_report_117_srpt_1_detail.data())
    #expect(senate.committeeReports.first?.associatedBill == nil)
    #expect(senate.committeeReports.first?.associatedTreaties == nil)
    let conference = try JSONDecoder().decode(
      CommitteeReportDetail.self,
      from: Fixture.committee_report_116_hrpt_333_conference_detail.data())
    #expect(conference.committeeReports.first?.isConferenceReport == true)
    #expect(conference.committeeReports.first?.committees == [])
  }

  @Test("Report identities validate positive decimal numbers and safe open types")
  func reportIdentitiesValidatePositiveDecimalNumbersAndSafeOpenTypes() throws {
    let identifier = try CommitteeReportIdentifier(
      congress: 1, number: "0005", type: .init(rawValue: "FUTURE"))
    #expect(identifier.number == "0005")
    #expect(identifier.type.rawValue == "future")
    #expect(CommitteeReportType.executiveReport.rawValue == "erpt")
    #expect(CommitteeReportType.houseReport.rawValue == "hrpt")
    #expect(CommitteeReportType.senateReport.rawValue == "srpt")
    #expect(
      try JSONDecoder().decode(CommitteeReportType.self, from: Data(#""FutureCode""#.utf8)).rawValue
        == "FutureCode")
    #expect(
      try JSONEncoder().encode(CommitteeReportType(rawValue: "FutureCode"))
        == Data(#""FutureCode""#.utf8))
    for number in ["", "0", "00", "-1", "1/2", "١", "1?part=2"] {
      #expect(throws: CongressInputError.invalidCommitteeReportIdentifier) {
        try CommitteeReportIdentifier(congress: 117, number: number, type: .houseReport)
      }
    }
    for code in ["", "hrpt/1", "hrpt?", "é", "hrpt1"] {
      #expect(throws: CongressInputError.invalidCommitteeReportIdentifier) {
        try CommitteeReportIdentifier(congress: 117, number: "1", type: .init(rawValue: code))
      }
      #expect(throws: CongressInputError.invalidQuery) {
        try CommitteeReportInventoryQuery(scope: .type(congress: 117, type: .init(rawValue: code)))
      }
    }
    #expect(throws: CongressInputError.invalidCommitteeReportIdentifier) {
      try CommitteeReportIdentifier(congress: 0, number: "1", type: .houseReport)
    }
    #expect(throws: CongressInputError.invalidQuery) {
      try CommitteeReportInventoryQuery(scope: .congress(0))
    }
    #expect(throws: CongressInputError.invalidQuery) {
      try CommitteeReportInventoryQuery(scope: .type(congress: -1, type: .houseReport))
    }
    #expect(throws: CongressInputError.invalidQuery) { try CommitteeReportInventoryQuery(limit: 0) }
    #expect(throws: CongressInputError.invalidQuery) {
      try CommitteeReportInventoryQuery(limit: 251)
    }
    #expect(throws: CongressInputError.invalidQuery) {
      try CommitteeReportInventoryQuery(offset: -1)
    }
  }

  @Test("Report inventory scopes conference values and date windows encode independently")
  func reportInventoryScopesConferenceValuesAndDateWindowsEncodeIndependently() throws {
    let scopes: [CommitteeReportInventoryQuery.Scope] = [
      .all, .congress(117), .type(congress: 117, type: .init(rawValue: "SRPT")),
    ]
    let paths = [
      "/v3/committee-report", "/v3/committee-report/117", "/v3/committee-report/117/srpt",
    ]
    for (scope, path) in zip(scopes, paths) {
      let plain = try CommitteeReportInventoryQuery(scope: scope)
      #expect(
        Endpoint.committeeReports(matching: plain).path == path + "?format=json&limit=20&offset=0")
      #expect(
        CongressRequest.committeeReports(matching: plain).resolution
          == .collection(.committeeReports(matching: plain)))
      for conference in [false, true] {
        let query = try CommitteeReportInventoryQuery(
          conference: conference, fromDateTime: "2020-01-01T00:00:00+00:00", limit: 2, offset: 4,
          scope: scope, toDateTime: "2020-01-02T00:00:00Z")
        #expect(
          Endpoint.committeeReports(matching: query).path == path
            + "?conference=\(conference)&format=json&fromDateTime=2020-01-01T00:00:00%2B00:00&limit=2&offset=4&toDateTime=2020-01-02T00:00:00Z"
        )
      }
    }
    let report = try CommitteeReportIdentifier(congress: 109, number: "519", type: .houseReport)
    #expect(
      Endpoint.committeeReport(report).path == "/v3/committee-report/109/hrpt/519?format=json")
    #expect(
      CongressRequest.committeeReport(report).resolution == .endpoint(.committeeReport(report)))
    let text = Endpoint.textVersions(for: report, page: try CongressQuery(limit: 1, offset: 3))
    #expect(text.path == "/v3/committee-report/109/hrpt/519/text?format=json&limit=1&offset=3")
    #expect(
      CongressRequest.textVersions(for: report).resolution
        == .collection(.textVersions(for: report)))
    let reference = try JSONDecoder().decode(
      CommitteeReportPage.self,
      from: Fixture.committee_house_hspw00_reports_chain_terminal.data()
    ).reports.first { $0.part == 2 }
    let value = try #require(reference)
    let fromReference = try CommitteeReportIdentifier(
      congress: value.congress, number: String(value.number), type: .init(rawValue: value.type))
    #expect(fromReference == report)
  }

  @Test("Report mutations preserve unknown null relative link and treaty letter values")
  func reportMutationsPreserveUnknownNullRelativeLinkAndTreatyLetterValues() throws {
    // Explicit policy mutations; these rare shapes were not observed in production captures.
    let bytes = Data(
      #"{"committeeReports":[{"congress":117,"number":5,"type":"Future","part":null,"associatedTreaties":[{"congress":117,"number":3,"part":"A","url":null}],"title":null,"future":true}],"request":null}"#
        .utf8)
    let detail = try JSONDecoder().decode(CommitteeReportDetail.self, from: bytes)
    let part = try #require(detail.committeeReports.first)
    #expect(part.part == nil && part.title == nil && part.committees == nil)
    #expect(part.type == "Future")
    #expect(part.associatedTreaties?.first?.part == "A")
    #expect(part.rawFields["part"] == .null && part.rawFields["committees"] == nil)
    #expect(
      try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(detail))
        == JSONDecoder().decode(JSONValue.self, from: bytes))
    let textBytes = Data(
      #"{"text":[{"formats":[{"type":"Future","isErrata":"Y","url":"../report.htm","extra":null},{"isErrata":"unknown","url":null}]},{"formats":null},{}],"pagination":{"count":3},"request":null}"#
        .utf8)
    let text = try JSONDecoder().decode(CommitteeReportTextPage.self, from: textBytes)
    #expect(text.items.first?.formats?.first?.isErrata == "Y")
    #expect(text.items.first?.formats?.first?.url == "../report.htm")
    #expect(text.items[1].formats == nil && text.items[2].formats == nil)
    #expect(
      try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(text))
        == JSONDecoder().decode(JSONValue.self, from: textBytes))
    for key in ["congress", "number", "type"] {
      for value: JSONValue? in [nil, .null, .boolean(true)] {
        var fields = part.rawFields
        fields[key] = value
        let invalid = try JSONEncoder().encode(fields)
        #expect(throws: DecodingError.self) {
          try JSONDecoder().decode(CommitteeReportPart.self, from: invalid)
        }
      }
    }
    let wrongBill = Data(#"{"congress":109,"number":5316,"type":"HR"}"#.utf8)
    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode(CommitteeReportBill.self, from: wrongBill)
    }
    let wrongTreaty = Data(#"{"congress":117,"number":"3"}"#.utf8)
    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode(CommitteeReportTreaty.self, from: wrongTreaty)
    }
    let wrongErrata = Data(#"{"isErrata":true}"#.utf8)
    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode(CommitteeReportTextFormat.self, from: wrongErrata)
    }
  }

  @Test("Report recorded conference comparisons preserve observed values without inference")
  func reportRecordedConferenceComparisonsPreserveObservedValuesWithoutInference() throws {
    let plain = try JSONDecoder().decode(
      CommitteeReportPage.self, from: Fixture.committee_report_117_inventory_first.data())
    let excluded = try JSONDecoder().decode(
      CommitteeReportPage.self, from: Fixture.committee_report_117_conference_false_first.data())
    let included = try JSONDecoder().decode(
      CommitteeReportPage.self, from: Fixture.committee_report_117_conference_true_first.data())
    #expect(plain.reports == excluded.reports)
    #expect(plain.pagination.count == 1013 && excluded.pagination.count == 1013)
    #expect(included.reports.isEmpty && included.pagination.count == 0)
  }

  @Test(
    "Reports retain every official fixture field and exact envelope",
    arguments: [
      Fixture.committee_report_inventory_first,
      Fixture.committee_report_117_inventory_first,
      Fixture.committee_report_117_conference_true_first,
      Fixture.committee_report_117_conference_false_first,
      Fixture.committee_report_117_srpt_first,
      Fixture.committee_report_109_hrpt_519_detail,
      Fixture.committee_report_117_erpt_5_detail,
      Fixture.committee_report_109_hrpt_519_text_first,
      Fixture.committee_report_117_srpt_chain_first,
      Fixture.committee_report_117_srpt_1_detail,
      Fixture.committee_report_116_hrpt_333_conference_detail,
      Fixture.committee_report_117_srpt_chain_next,
      Fixture.committee_report_109_hrpt_519_text_next,
      Fixture.committee_report_117_srpt_chain_terminal,
      Fixture.committee_report_109_hrpt_519_text_third,
      Fixture.committee_report_109_hrpt_519_text_terminal,
    ])
  func reportsRetainEveryOfficialFixtureFieldAndExactEnvelope(fixture: Fixture) throws {
    let bytes = try fixture.data()
    let raw = try JSONDecoder().decode([String: JSONValue].self, from: bytes)
    let encoded: Data
    if raw["committeeReports"] != nil {
      let detail = try JSONDecoder().decode(CommitteeReportDetail.self, from: bytes)
      #expect(detail.request == raw["request"])
      #expect(
        detail.committeeReports.map(\.rawFields)
          == raw["committeeReports"]?.array?.compactMap(\.object))
      for part in detail.committeeReports {
        #expect(part.congress == part.rawFields["congress"]?.integer)
        #expect(part.number == part.rawFields["number"]?.integer)
        #expect(part.part == part.rawFields["part"]?.integer)
        #expect(part.type == part.rawFields["type"]?.string)
        #expect(part.chamber == part.rawFields["chamber"]?.string)
        #expect(part.citation == part.rawFields["citation"]?.string)
        #expect(part.issueDate == part.rawFields["issueDate"]?.string)
        #expect(part.reportType == part.rawFields["reportType"]?.string)
        #expect(part.sessionNumber == part.rawFields["sessionNumber"]?.integer)
        #expect(part.title == part.rawFields["title"]?.string)
        #expect(part.updateDate == part.rawFields["updateDate"]?.string)
        #expect(
          part.rawFields["isConferenceReport"] == part.isConferenceReport.map(JSONValue.boolean))
        #expect(part.text?.rawFields == part.rawFields["text"]?.object)
        for bill in part.associatedBill ?? [] {
          #expect(bill.congress == bill.rawFields["congress"]?.integer)
          #expect(bill.number == bill.rawFields["number"]?.string)
          #expect(bill.type == bill.rawFields["type"]?.string)
          #expect(bill.url == bill.rawFields["url"]?.string)
        }
        for treaty in part.associatedTreaties ?? [] {
          #expect(treaty.congress == treaty.rawFields["congress"]?.integer)
          #expect(treaty.number == treaty.rawFields["number"]?.integer)
          #expect(treaty.part == treaty.rawFields["part"]?.string)
          #expect(treaty.url == treaty.rawFields["url"]?.string)
        }
        #expect(
          part.committees?.map(\.rawFields)
            == part.rawFields["committees"]?.array?.compactMap(\.object))
        #expect(
          part.associatedBill?.map(\.rawFields)
            == part.rawFields["associatedBill"]?.array?.compactMap(\.object))
        #expect(
          part.associatedTreaties?.map(\.rawFields)
            == part.rawFields["associatedTreaties"]?.array?.compactMap(\.object))
      }
      encoded = try JSONEncoder().encode(detail)
    } else if raw["text"] != nil {
      let page = try JSONDecoder().decode(CommitteeReportTextPage.self, from: bytes)
      #expect(page.request == raw["request"])
      #expect(page.text == page.items)
      #expect(page.items.map(\.rawFields) == raw["text"]?.array?.compactMap(\.object))
      #expect(page.pagination.count == 4)
      for record in page.items {
        #expect(
          record.formats?.map(\.rawFields)
            == record.rawFields["formats"]?.array?.compactMap(\.object))
        for format in record.formats ?? [] {
          #expect(format.isErrata == "N")
          #expect(format.type == format.rawFields["type"]?.string)
          #expect(format.url == format.rawFields["url"]?.string)
        }
      }
      encoded = try JSONEncoder().encode(page)
    } else {
      let page = try JSONDecoder().decode(CommitteeReportPage.self, from: bytes)
      #expect(page.request == raw["request"])
      #expect(page.items.map(\.rawFields) == raw["reports"]?.array?.compactMap(\.object))
      for report in page.items {
        #expect(report.congress == report.rawFields["congress"]?.integer)
        #expect(report.number == report.rawFields["number"]?.integer)
        #expect(report.part == report.rawFields["part"]?.integer)
        #expect(report.type == report.rawFields["type"]?.string)
      }
      encoded = try JSONEncoder().encode(page)
    }
    #expect(try JSONDecoder().decode(JSONValue.self, from: encoded) == .object(raw))
  }
}
