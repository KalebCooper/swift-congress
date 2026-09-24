#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import SwiftCongressDataModels
import SwiftCongressDataTestSupport
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct CongressModelsTests {
  @Test(
    "All source fields survive bill decoding and encoding",
    arguments: [Fixture.bill6, .bill82, .bill119])
  func allSourceFieldsSurviveBillDecodingAndEncoding(fixture: Fixture) throws {
    let bytes = try fixture.data()
    let detail = try JSONDecoder().decode(BillDetail.self, from: bytes)
    let original = try JSONDecoder().decode(JSONValue.self, from: bytes)
    let encoded = try JSONEncoder().encode(detail)
    #expect(try JSONDecoder().decode(JSONValue.self, from: encoded) == original)
    #expect(!detail.bill.title.isEmpty)
  }

  @Test("Continuation advances the same source query")
  func continuationAdvancesTheSameSourceQuery() throws {
    let page = try JSONDecoder().decode(BillPage.self, from: Fixture.bills6_first.data())
    let endpoint = Endpoint.bills(matching: try BillQuery(congress: 6, limit: 2))
    let next = try CongressContinuation.next(after: page, endpoint: endpoint)
    #expect(next?.path == "/v3/bill/6?offset=2&limit=2&format=json")
    let second = try JSONDecoder().decode(BillPage.self, from: Fixture.bills6_next.data())
    #expect(
      try CongressContinuation.next(after: second, endpoint: #require(next))?.path
        == "/v3/bill/6?offset=4&limit=2&format=json")
  }

  @Test("Historical source keys are not promoted to numbered bills")
  func historicalSourceKeysAreNotPromotedToNumberedBills() throws {
    let source = try BillSourceIdentifier(congress: 6, number: "1", type: .houseBill)
    #expect(Endpoint.bill(source).path == "/v3/bill/6/hr/1?format=json")
    #expect(throws: CongressInputError.invalidBillIdentifier) {
      try BillIdentifier(congress: 6, number: "1", type: .houseBill)
    }
    let old = try JSONDecoder().decode(BillDetail.self, from: Fixture.bill82.data())
    #expect(old.bill.sponsors == nil)
    #expect(old.bill.rawFields["laws"]?.array?.first?.object?["number"] == .string("82-416"))
  }

  @Test(
    "Invalid pagination fails before yielding the page",
    arguments: [
      "https://api.congress.gov/v3/bill/6?offset=0&limit=2&format=json",
      "https://api.congress.gov/v3/bill/82?offset=2&limit=2&format=json",
      "https://api.congress.gov/v3/bill/6?offset=2&limit=250&format=json",
      "https://api.congress.gov/v3/bill/6?offset=2&offset=4&limit=2&format=json",
      "https://example.com/v3/bill/6?offset=2&limit=2&format=json", "",
    ])
  func invalidPaginationFailsBeforeYieldingThePage(link: String) throws {
    var object = try JSONDecoder().decode(
      [String: JSONValue].self, from: Fixture.bills6_first.data())
    object["pagination"] = .object(["count": .number(80), "next": .string(link)])
    let page = try JSONDecoder().decode(BillPage.self, from: JSONEncoder().encode(object))
    #expect(throws: CongressPaginationError.invalidContinuation) {
      try CongressContinuation.next(
        after: page, endpoint: .bills(matching: BillQuery(congress: 6, limit: 2)))
    }
  }

  @Test(
    "Invalid source links never become credentialed endpoints",
    arguments: [
      "https://example.com/v3/bill", "http://api.congress.gov/v3/bill",
      "https://api.congress.gov:444/v3/bill",
      "https://user@api.congress.gov/v3/bill", "https://api.congress.gov/v3/bill#fragment",
      "https://api.congress.gov/v3/bill?api_key=secret", "https://api.congress.gov/v3/%2e%2e/bill",
      "https://api.congress.gov/v3/%252e%252e/bill",
    ])
  func invalidSourceLinksNeverBecomeCredentialedEndpoints(link: String) throws {
    #expect(Endpoint<BillPage>(link: try #require(URL(string: link))) == nil)
  }

  @Test("Missing continuation fails for an incomplete page")
  func missingContinuationFailsForAnIncompletePage() throws {
    var object = try JSONDecoder().decode(
      [String: JSONValue].self, from: Fixture.bills6_first.data())
    object["pagination"] = .object(["count": .number(80)])
    let page = try JSONDecoder().decode(BillPage.self, from: JSONEncoder().encode(object))
    #expect(throws: CongressPaginationError.invalidContinuation) {
      try CongressContinuation.next(
        after: page, endpoint: .bills(matching: BillQuery(congress: 6, limit: 2)))
    }
  }

  @Test("The earliest Congress preserves its missing session number")
  func theEarliestCongressPreservesItsMissingSessionNumber() throws {
    let page = try JSONDecoder().decode(CongressPage.self, from: Fixture.congresses_last.data())
    #expect(page.congresses.first?.name == "1st Congress")
    #expect(page.congresses.first?.sessions?.last?.number == nil)
    #expect(
      try CongressContinuation.next(
        after: page, endpoint: .congresses(matching: .init(limit: 2, offset: 118))) == nil)
  }
}
