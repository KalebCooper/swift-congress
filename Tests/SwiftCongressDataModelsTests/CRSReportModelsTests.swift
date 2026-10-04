#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import SwiftCongressDataModels
import SwiftCongressDataTestSupport
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct CRSReportModelsTests {
  @Test(
    "CRS detail fixtures retain nested metadata and raw fields",
    arguments: [Fixture.crs_report_if10199, .crs_report_r47175])
  func crsDetailFixturesRetainNestedMetadataAndRawFields(fixture: Fixture) throws {
    let bytes = try fixture.data()
    let detail = try JSONDecoder().decode(CRSReportDetail.self, from: bytes)
    #expect(
      try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(detail))
        == JSONDecoder().decode(JSONValue.self, from: bytes))
    let report = detail.report
    #expect(report.formats?.map(\.format) == ["PDF", "HTML"])
    #expect(report.authors?.isEmpty == false)
    #expect(report.topics?.isEmpty == false)
    #expect(report.url == "www.congress.gov/crs-report/\(report.id)")
    let materials = try #require(report.relatedMaterials)
    #expect(materials[0].number?.string != nil)
    #expect(materials[0].title == nil)
    #expect(materials[0].rawFields["title"] == .null)
    #expect(materials[1...].contains { $0.number?.integer != nil })
    #expect(materials.allSatisfy { $0.url == $0.rawFields["URL"]?.string })
    if report.id == "R47175" {
      #expect(materials[1] == materials[2])
      #expect(report.authors?.first?.author == "Megan S. Lynch")
      #expect(report.topics?.first?.topic == "Budget & Appropriations Procedure")
      #expect(report.currentVersion == 2)
    } else {
      #expect(report.currentVersion == 49)
      #expect(report.authors?.count == 4)
    }
  }

  @Test("CRS identifiers preserve open prefixes and reject unsafe components")
  func crsIdentifiersPreserveOpenPrefixesAndRejectUnsafeComponents() throws {
    for value in [
      "R47175", "RS21852", "IF10199", "future-01_a", String(repeating: "A", count: 100),
    ] {
      let id = try CRSReportIdentifier(rawValue: value)
      #expect(id.rawValue == value)
      #expect(Endpoint.crsReport(id).path == "/v3/crsreport/\(value)?format=json")
      #expect(CongressRequest.crsReport(id).resolution == .endpoint(.crsReport(id)))
    }
    for value in ["", ".", "..", "R/1", "R%2F1", "R?key", "R#1", " R1", "é", "R\n"] {
      #expect(throws: CongressInputError.invalidCRSReportIdentifier) {
        try CRSReportIdentifier(rawValue: value)
      }
    }
  }

  @Test(
    "CRS inventories retain independent dates versions and complete raw envelopes",
    arguments: [
      Fixture.crs_reports_day_first, .crs_reports_day_inventory,
      .crs_reports_day_terminal, .crs_reports_first, .crs_reports_window_first,
    ])
  func crsInventoriesRetainIndependentDatesVersionsAndCompleteRawEnvelopes(fixture: Fixture) throws
  {
    let bytes = try fixture.data()
    let page = try JSONDecoder().decode(CRSReportPage.self, from: bytes)
    #expect(page.items == page.reports)
    #expect(
      try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(page))
        == JSONDecoder().decode(JSONValue.self, from: bytes))
    if let report = page.items.first(where: { $0.id == "IF10199" }) {
      #expect(report.version == 41)
      #expect(report.publishDate == "2026-06-30T04:00:00Z")
      #expect(report.updateDate == "2026-10-03T16:53:27Z")
    }
    if fixture == .crs_reports_window_first {
      #expect(page.pagination.count == 1)
      #expect(page.items.first?.updateDate == "2026-10-03T12:22:58Z")
    }
  }

  @Test("CRS queries encode only paging and source date filters")
  func crsQueriesEncodeOnlyPagingAndSourceDateFilters() throws {
    let query = try CRSReportQuery(
      fromDateTime: "2026-10-03T00:00:00+00:00",
      limit: 250, offset: 5, toDateTime: "2026-10-04T00:00:00Z")
    #expect(
      Endpoint.crsReports(matching: query).path
        == "/v3/crsreport?format=json&fromDateTime=2026-10-03T00:00:00%2B00:00&limit=250&offset=5&toDateTime=2026-10-04T00:00:00Z"
    )
    #expect(
      CongressRequest.crsReports(matching: query).resolution
        == .collection(.crsReports(matching: query)))
    #expect(
      try Endpoint.crsReports(matching: CRSReportQuery()).path
        == "/v3/crsreport?format=json&limit=20&offset=0")
    #expect(throws: CongressInputError.invalidQuery) { try CRSReportQuery(limit: 0) }
    #expect(throws: CongressInputError.invalidQuery) { try CRSReportQuery(limit: 251) }
    #expect(throws: CongressInputError.invalidQuery) { try CRSReportQuery(offset: -1) }
  }

  @Test("CRS sparse unknown and null records remain source faithful")
  func crsSparseUnknownAndNullRecordsRemainSourceFaithful() throws {
    // Labeled decoder-policy mutations, not additional provider evidence.
    let raw = Data(
      #"{"id":"Future","title":"Example","status":"FutureStatus","contentType":"FutureType","summary":null,"extra":{"null":null}}"#
        .utf8)
    let report = try JSONDecoder().decode(CRSReport.self, from: raw)
    #expect(report.status == "FutureStatus")
    #expect(report.contentType == "FutureType")
    #expect(report.authors == nil)
    #expect(report.currentVersion == nil)
    #expect(report.formats == nil)
    #expect(report.publishDate == nil)
    #expect(report.relatedMaterials == nil)
    #expect(report.summary == nil)
    #expect(report.topics == nil)
    #expect(report.updateDate == nil)
    #expect(
      try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(report))
        == JSONDecoder().decode(JSONValue.self, from: raw))
    let summary = try JSONDecoder().decode(CRSReportSummary.self, from: raw)
    #expect(summary.version == nil)
    for missing in ["id", "title"] {
      var fields = report.rawFields
      fields.removeValue(forKey: missing)
      let bytes = try JSONEncoder().encode(fields)
      #expect(throws: DecodingError.self) { try JSONDecoder().decode(CRSReport.self, from: bytes) }
      #expect(throws: DecodingError.self) {
        try JSONDecoder().decode(CRSReportSummary.self, from: bytes)
      }
    }
  }

  @Test("CRS wrapper capitalization is exact")
  func crsWrapperCapitalizationIsExact() throws {
    var detail = try JSONDecoder().decode(
      [String: JSONValue].self, from: Fixture.crs_report_r47175.data())
    detail["crsReport"] = detail.removeValue(forKey: "CRSReport")
    let detailBytes = try JSONEncoder().encode(detail)
    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode(CRSReportDetail.self, from: detailBytes)
    }
    var page = try JSONDecoder().decode(
      [String: JSONValue].self, from: Fixture.crs_reports_day_first.data())
    page["crsReports"] = page.removeValue(forKey: "CRSReports")
    let pageBytes = try JSONEncoder().encode(page)
    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode(CRSReportPage.self, from: pageBytes)
    }
  }
}
