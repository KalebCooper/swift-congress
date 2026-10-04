#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import SwiftCongressDataModels
import SwiftCongressDataTestSupport
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct SummaryModelsTests {
  @Test(
    "Bill summary pages round trip every source field",
    arguments: [
      Fixture.bill119_summaries_first, .bill119_summaries_next,
      .bill119_summaries_terminal, .bill82_summaries_sparse,
    ])
  func billSummaryPagesRoundTripEverySourceField(fixture: Fixture) throws {
    let bytes = try fixture.data()
    let page = try JSONDecoder().decode(BillSummaryPage.self, from: bytes)
    #expect(page.items == page.summaries)
    #expect(
      try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(page))
        == JSONDecoder().decode(JSONValue.self, from: bytes))
  }

  @Test("Historical summaries are empty without imposing a historical cutoff")
  func historicalSummariesAreEmptyWithoutImposingAHistoricalCutoff() throws {
    let page = try JSONDecoder().decode(
      BillSummaryPage.self, from: Fixture.bill82_summaries_sparse.data())
    #expect(page.summaries.isEmpty)
    #expect(page.pagination.count == 0)
    let early = try BillSourceIdentifier(congress: 6, number: "1", type: .houseBill)
    #expect(
      Endpoint.summaries(for: early).path
        == "/v3/bill/6/hr/1/summaries?format=json&limit=20&offset=0")
  }

  @Test("Recorded summaries preserve HTML and leading zero version codes")
  func recordedSummariesPreserveHTMLAndLeadingZeroVersionCodes() throws {
    let pages = try [
      Fixture.bill119_summaries_first, .bill119_summaries_next,
      .bill119_summaries_terminal,
    ].map {
      try JSONDecoder().decode(BillSummaryPage.self, from: $0.data())
    }
    let versions = pages.flatMap(\.summaries)
    #expect(versions.count == 5)
    #expect(versions.contains { $0.versionCode == "00" })
    #expect(versions.contains { $0.versionCode == "07" })
    #expect(versions.allSatisfy { $0.text?.contains("<") == true })
    #expect(versions.allSatisfy { $0.rawFields["bill"] == nil })
    let numbered = try BillIdentifier(congress: 119, number: "1", type: .houseBill)
    #expect(Endpoint.summaries(for: numbered) == Endpoint.summaries(for: numbered.source))
    #expect(
      CongressRequest.summaries(for: numbered) == CongressRequest.summaries(for: numbered.source))
  }

  @Test("Summary mutations preserve null omitted empty and unknown source values")
  func summaryMutationsPreserveNullOmittedEmptyAndUnknownSourceValues() throws {
    // Labeled mutation of an official row; this is decoder behavior, not historical evidence.
    let page = try JSONDecoder().decode(
      BillSummaryPage.self, from: Fixture.bill119_summaries_first.data())
    var row = try #require(page.summaries.first?.rawFields)
    row["actionDate"] = .null
    row.removeValue(forKey: "actionDesc")
    row["text"] = .string("")
    row["versionCode"] = .string("future")
    row["unknown"] = .array([.null, .string("retained")])
    let summary = try JSONDecoder().decode(BillSummary.self, from: JSONEncoder().encode(row))
    #expect(summary.actionDate == nil)
    #expect(summary.actionDesc == nil)
    #expect(summary.rawFields["actionDate"] == .null)
    #expect(summary.rawFields["actionDesc"] == nil)
    #expect(summary.text == "")
    #expect(summary.versionCode == "future")
    #expect(
      try JSONDecoder().decode([String: JSONValue].self, from: JSONEncoder().encode(summary)) == row
    )
    row["text"] = .number(1)
    #expect(throws: (any Error).self) {
      try JSONDecoder().decode(BillSummary.self, from: JSONEncoder().encode(row))
    }
  }

  @Test("Summary queries preserve defaults windows scopes and encoded sort")
  func summaryQueriesPreserveDefaultsWindowsScopesAndEncodedSort() throws {
    #expect(
      try Endpoint.summaryUpdates(matching: SummaryQuery()).path
        == "/v3/summaries?format=json&limit=20&offset=0")
    #expect(
      try Endpoint.summaryUpdates(matching: SummaryQuery(scope: .congress(1))).path
        == "/v3/summaries/1?format=json&limit=20&offset=0")
    let query = try SummaryQuery(
      fromDateTime: "2026-09-01T00:00:00Z", limit: 2, offset: 4,
      scope: .billType(congress: 119, type: .init(rawValue: "HR")),
      sort: .updateDateAscending, toDateTime: "2026-09-02T00:00:00Z")
    #expect(
      Endpoint.summaryUpdates(matching: query).path
        == "/v3/summaries/119/hr?format=json&fromDateTime=2026-09-01T00:00:00Z&limit=2&offset=4&sort=updateDate%2Basc&toDateTime=2026-09-02T00:00:00Z"
    )
    #expect(throws: CongressInputError.invalidQuery) { try SummaryQuery(limit: 0) }
    #expect(throws: CongressInputError.invalidQuery) { try SummaryQuery(limit: 251) }
    #expect(throws: CongressInputError.invalidQuery) { try SummaryQuery(offset: -1) }
    #expect(throws: CongressInputError.invalidQuery) { try SummaryQuery(scope: .congress(0)) }
    #expect(throws: CongressInputError.invalidQuery) {
      try SummaryQuery(scope: .billType(congress: -1, type: .houseBill))
    }
    #expect(throws: CongressInputError.invalidQuery) {
      try SummaryQuery(scope: .billType(congress: 119, type: .init(rawValue: "../hr")))
    }
    #expect(throws: CongressInputError.invalidQuery) {
      try SummaryQuery(scope: .billType(congress: 119, type: .init(rawValue: "")))
    }
  }

  @Test("Summary update mutations retain chamber codes and require a real bill")
  func summaryUpdateMutationsRetainChamberCodesAndRequireARealBill() throws {
    // Labeled mutation: optional scalar nulls and future fields do not fabricate a bill.
    let page = try JSONDecoder().decode(
      BillSummaryUpdatePage.self, from: Fixture.summary_updates119_hr_window.data())
    var row = try #require(page.summaries.first?.rawFields)
    row["currentChamber"] = .null
    row["currentChamberCode"] = .string("future")
    row.removeValue(forKey: "lastSummaryUpdateDate")
    row["future"] = .boolean(true)
    let value = try JSONDecoder().decode(BillSummaryUpdate.self, from: JSONEncoder().encode(row))
    #expect(value.currentChamber == nil)
    #expect(value.currentChamberCode == "future")
    #expect(value.lastSummaryUpdateDate == nil)
    #expect(
      try JSONDecoder().decode([String: JSONValue].self, from: JSONEncoder().encode(value)) == row)
    row.removeValue(forKey: "bill")
    #expect(throws: (any Error).self) {
      try JSONDecoder().decode(BillSummaryUpdate.self, from: JSONEncoder().encode(row))
    }
  }

  @Test(
    "Summary update pages retain nested bills and round trip the source",
    arguments: [
      Fixture.summary_updates_default, .summary_updates_window,
      .summary_updates_window_next, .summary_updates_window_unsorted_first,
      .summary_updates_window_unsorted_next, .summary_updates_window_unsorted_terminal,
      .summary_updates_window_unsorted_third, .summary_updates119_window,
      .summary_updates119_hr_window,
    ])
  func summaryUpdatePagesRetainNestedBillsAndRoundTripTheSource(fixture: Fixture) throws {
    let bytes = try fixture.data()
    let page = try JSONDecoder().decode(BillSummaryUpdatePage.self, from: bytes)
    #expect(page.items == page.summaries)
    #expect(!page.summaries.isEmpty)
    #expect(page.summaries.allSatisfy { $0.bill.congress > 0 })
    #expect(page.summaries.allSatisfy { $0.lastSummaryUpdateDate != nil })
    #expect(
      try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(page))
        == JSONDecoder().decode(JSONValue.self, from: bytes))
  }
}
