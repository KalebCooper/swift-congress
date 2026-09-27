#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import SwiftCongressDataModels
import SwiftCongressDataTestSupport
import Testing

extension CongressRequest where Response == BillTextVersionPage {
  static var earliestHouseBillTextExample: Self {
    get throws {
      .textVersions(for: try BillSourceIdentifier(congress: 6, number: "1", type: .houseBill))
    }
  }
}

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct BillTextModelsTests {
  private static let textFixtures: [Fixture] = [
    .bill119_text_first, .bill119_text_next, .bill119_text_terminal, .bill6_text, .bill82_text,
  ]

  private func decode<Value: Decodable>(_ type: Value.Type, _ fixture: Fixture) throws -> Value {
    try JSONDecoder().decode(type, from: fixture.data())
  }

  private func decode<Value: Decodable>(
    _ type: Value.Type, _ fixture: Fixture, mutating: (inout [String: JSONValue]) -> Void
  ) throws -> Value {
    var object = try JSONDecoder().decode([String: JSONValue].self, from: fixture.data())
    mutating(&object)
    return try JSONDecoder().decode(type, from: JSONEncoder().encode(object))
  }

  private func firstPage(appending count: Int, next: String) throws -> BillTextVersionPage {
    try decode(BillTextVersionPage.self, .bill119_text_first) { object in
      var versions = object["textVersions"]?.array ?? []
      for _ in 0..<count { versions.append(versions[0]) }
      object["textVersions"] = .array(versions)
      object["pagination"] = .object(["count": .number(6), "next": .string(next)])
    }
  }

  private func houseBill119() throws -> BillSourceIdentifier {
    try BillSourceIdentifier(congress: 119, number: "1", type: .houseBill)
  }

  @Test(
    "All source fields survive text version page decoding and encoding",
    arguments: BillTextModelsTests.textFixtures)
  func allSourceFieldsSurviveTextVersionPageDecodingAndEncoding(fixture: Fixture) throws {
    let bytes = try fixture.data()
    let page = try JSONDecoder().decode(BillTextVersionPage.self, from: bytes)
    let original = try JSONDecoder().decode(JSONValue.self, from: bytes)
    let encoded = try JSONEncoder().encode(page)
    #expect(try JSONDecoder().decode(JSONValue.self, from: encoded) == original)
    #expect(page.items == page.textVersions)
    #expect(!page.textVersions.isEmpty)
    #expect(page.request?.object?["contentType"] == .string("application/json"))
    #expect(page.textVersions.allSatisfy({ $0.formats?.isEmpty == false }))
  }

  @Test("Recorded versions keep source names, dates, and format links")
  func recordedVersionsKeepSourceNamesDatesAndFormatLinks() throws {
    let page = try decode(BillTextVersionPage.self, .bill119_text_first)
    #expect(page.pagination.count == 6)
    #expect(
      page.textVersions.map(\.type) == [
        "Enrolled Bill", "Engrossed Amendment Senate", "Public Law",
      ])
    let enrolled = try #require(page.textVersions.first)
    #expect(enrolled.date == nil)
    #expect(enrolled.rawFields["date"] == .null)
    #expect(
      enrolled.formats?.map(\.type) == [
        "Formatted Text", "PDF", "United States Legislative Markup", "Formatted XML",
      ])
    let pdf = try #require(enrolled.formats?[1])
    #expect(pdf.url == "https://www.congress.gov/119/bills/hr1/BILLS-119hr1enr.pdf")
    #expect(pdf.parsedURL?.host == "www.congress.gov")
    #expect(pdf.parsedURL?.path == "/119/bills/hr1/BILLS-119hr1enr.pdf")
    #expect(pdf.rawFields.keys.sorted() == ["type", "url"])
    #expect(page.textVersions[1].date == "2025-07-01T04:00:00Z")
    #expect(page.textVersions[2].date == "2025-07-05T03:59:59Z")

    let earliest = try decode(BillTextVersionPage.self, .bill6_text)
    let version = try #require(earliest.textVersions.first)
    #expect(version.type == "Bill Text Version 1")
    #expect(version.date == "1799-12-16T12:00:00Z")
    #expect(version.formats?.map(\.type) == ["PDF", "Plain Text"])
    #expect(
      version.formats?.last?.url
        == "https://www.congress.gov/6/llhb/6_HR1_BillTextVersion1_12161799.txt")
    let statute = try decode(BillTextVersionPage.self, .bill82_text)
    #expect(statute.textVersions.map(\.type) == ["Public Law"])
    #expect(statute.textVersions.first?.date == "1952-06-28T04:00:00Z")
    #expect(
      statute.textVersions.first?.formats?.map(\.url) == [
        "https://www.congress.gov/82/statute/STATUTE-66/STATUTE-66-Pg282-2.pdf"
      ])
  }

  @Test("Recorded pages keep the repeated final version in source order")
  func recordedPagesKeepTheRepeatedFinalVersionInSourceOrder() throws {
    let first = try decode(BillTextVersionPage.self, .bill119_text_first)
    let next = try decode(BillTextVersionPage.self, .bill119_text_next)
    let terminal = try decode(BillTextVersionPage.self, .bill119_text_terminal)
    #expect(first.textVersions.count == 3)
    #expect(next.textVersions.count == 3)
    #expect(terminal.textVersions.count == 1)
    #expect(
      next.textVersions.map(\.type) == [
        "Placed on Calendar Senate", "Engrossed in House", "Public Law",
      ])
    #expect(first.textVersions[2] == terminal.textVersions[0])
    #expect(next.textVersions[2] == terminal.textVersions[0])
  }

  @Test("Continuation follows the recorded text version links")
  func continuationFollowsTheRecordedTextVersionLinks() throws {
    let endpoint = try Endpoint.textVersions(for: houseBill119(), page: CongressQuery(limit: 2))
    #expect(endpoint.path == "/v3/bill/119/hr/1/text?format=json&limit=2&offset=0")
    let next = try CongressContinuation.next(
      after: decode(BillTextVersionPage.self, .bill119_text_first), endpoint: endpoint)
    #expect(next?.path == "/v3/bill/119/hr/1/text?offset=2&limit=2&format=json")
    let third = try CongressContinuation.next(
      after: decode(BillTextVersionPage.self, .bill119_text_next), endpoint: #require(next))
    #expect(third?.path == "/v3/bill/119/hr/1/text?offset=4&limit=2&format=json")

    let terminal = try decode(BillTextVersionPage.self, .bill119_text_terminal)
    #expect(terminal.pagination.next == nil)
    let lastLink = try #require(
      URL(string: "https://api.congress.gov/v3/bill/119/hr/1/text?offset=5&limit=2&format=json"))
    let last = try #require(Endpoint<BillTextVersionPage>(link: lastLink))
    #expect(try CongressContinuation.next(after: terminal, endpoint: last) == nil)
    #expect(
      try CongressContinuation.next(
        after: terminal,
        endpoint: .textVersions(for: houseBill119(), page: CongressQuery(limit: 2, offset: 5)))
        == nil)

    let earliest = try BillSourceIdentifier(congress: 6, number: "1", type: .houseBill)
    #expect(
      try CongressContinuation.next(
        after: decode(BillTextVersionPage.self, .bill6_text), endpoint: .textVersions(for: earliest)
      )
        == nil)
  }

  @Test("A text version page more than one version over its limit fails before yielding")
  func aTextVersionPageMoreThanOneVersionOverItsLimitFailsBeforeYielding() throws {
    let endpoint = try Endpoint.textVersions(for: houseBill119(), page: CongressQuery(limit: 2))
    let link = "https://api.congress.gov/v3/bill/119/hr/1/text?offset=2&limit=2&format=json"
    let overrun = try firstPage(appending: 1, next: link)
    #expect(overrun.textVersions.count == 4)
    #expect(throws: CongressPaginationError.invalidContinuation) {
      try CongressContinuation.next(after: overrun, endpoint: endpoint)
    }
    let countAdvanced = try firstPage(
      appending: 0,
      next: "https://api.congress.gov/v3/bill/119/hr/1/text?offset=3&limit=2&format=json")
    #expect(throws: CongressPaginationError.invalidContinuation) {
      try CongressContinuation.next(after: countAdvanced, endpoint: endpoint)
    }
    let otherBill = try firstPage(
      appending: 0,
      next: "https://api.congress.gov/v3/bill/119/hr/2/text?offset=2&limit=2&format=json")
    #expect(throws: CongressPaginationError.invalidContinuation) {
      try CongressContinuation.next(after: otherBill, endpoint: endpoint)
    }
  }

  @Test("Other collections still reject a page one record over its limit")
  func otherCollectionsStillRejectAPageOneRecordOverItsLimit() throws {
    let bills = try decode(BillPage.self, .bills6_first) { object in
      var records = object["bills"]?.array ?? []
      records.append(records[0])
      object["bills"] = .array(records)
    }
    #expect(bills.bills.count == 3)
    #expect(throws: CongressPaginationError.invalidContinuation) {
      try CongressContinuation.next(
        after: bills, endpoint: .bills(matching: BillQuery(congress: 6, limit: 2)))
    }
    let members = try decode(MemberPage.self, .members117_first) { object in
      var records = object["members"]?.array ?? []
      records.append(records[0])
      object["members"] = .array(records)
    }
    #expect(members.members.count == 3)
    #expect(throws: CongressPaginationError.invalidContinuation) {
      try CongressContinuation.next(
        after: members, endpoint: .members(matching: MemberQuery(limit: 2, scope: .congress(117))))
    }
    let actions = try decode(BillActionPage.self, .actions119) { object in
      let records = object["actions"]?.array ?? []
      object["actions"] = .array(Array(records.prefix(3)))
      object["pagination"] = .object([
        "count": .number(10),
        "next": .string(
          "https://api.congress.gov/v3/bill/119/hr/1/actions?offset=2&limit=2&format=json"),
      ])
    }
    #expect(actions.actions.count == 3)
    #expect(throws: CongressPaginationError.invalidContinuation) {
      try CongressContinuation.next(
        after: actions,
        endpoint: .actions(for: houseBill119(), page: CongressQuery(limit: 2)))
    }
  }

  @Test("Null dates, unknown formats, and empty arrays are preserved")
  func nullDatesUnknownFormatsAndEmptyArraysArePreserved() throws {
    let page = try decode(BillTextVersionPage.self, .bill119_text_first) { object in
      var versions = object["textVersions"]?.array ?? []
      var dated = versions[1].object ?? [:]
      dated["date"] = .null
      dated["formats"] = .array([
        .object(["type": .string("Braille Ready"), "url": .string("https://example.com/a.brf")]),
        .object(["type": .null, "note": .string("x")]),
      ])
      dated["versionCode"] = .string("eas")
      versions[1] = .object(dated)
      var empty = versions[2].object ?? [:]
      empty["formats"] = .array([])
      empty.removeValue(forKey: "type")
      versions[2] = .object(empty)
      var absent = versions[0].object ?? [:]
      absent.removeValue(forKey: "formats")
      absent.removeValue(forKey: "date")
      versions[0] = .object(absent)
      versions.append(.object(["formats": .null]))
      object["textVersions"] = .array(versions)
    }
    let absent = page.textVersions[0]
    #expect(absent.formats == nil)
    #expect(absent.date == nil)
    #expect(absent.rawFields["date"] == nil)
    #expect(absent.type == "Enrolled Bill")
    let dated = page.textVersions[1]
    #expect(dated.date == nil)
    #expect(dated.rawFields["date"] == .null)
    #expect(dated.rawFields["versionCode"] == .string("eas"))
    #expect(dated.formats?.first?.type == "Braille Ready")
    #expect(dated.formats?.last?.type == nil)
    #expect(dated.formats?.last?.url == nil)
    #expect(dated.formats?.last?.parsedURL == nil)
    #expect(dated.formats?.last?.rawFields["type"] == .null)
    #expect(dated.formats?.last?.rawFields["note"] == .string("x"))
    let empty = page.textVersions[2]
    #expect(empty.formats == [])
    #expect(empty.type == nil)
    let null = page.textVersions[3]
    #expect(null.formats == nil)
    #expect(null.rawFields["formats"] == .null)
    let reencoded = try JSONDecoder().decode(
      BillTextVersionPage.self, from: JSONEncoder().encode(page))
    #expect(reencoded == page)
    #expect(reencoded.textVersions[3].rawFields["formats"] == .null)

    let emptyPage = try decode(BillTextVersionPage.self, .bill6_text) { object in
      object["textVersions"] = .array([])
      object["pagination"] = .object(["count": .number(0)])
    }
    #expect(emptyPage.textVersions.isEmpty)
    #expect(
      try CongressContinuation.next(
        after: emptyPage,
        endpoint: .textVersions(
          for: BillSourceIdentifier(congress: 6, number: "1", type: .houseBill))) == nil)
  }

  @Test(
    "Malformed format links keep their source string without a parsed URL",
    arguments: [
      "not a url", "/119/bills/hr1/BILLS-119hr1enr.pdf", "", "https://", "www.congress.gov/a.pdf",
      "https://www.congress.gov/119/bills/hr1/BILLS 119hr1enr.pdf",
    ])
  func malformedFormatLinksKeepTheirSourceStringWithoutAParsedURL(link: String) throws {
    let page = try decode(BillTextVersionPage.self, .bill82_text) { object in
      var versions = object["textVersions"]?.array ?? []
      var version = versions[0].object ?? [:]
      version["formats"] = .array([.object(["type": .string("PDF"), "url": .string(link)])])
      versions[0] = .object(version)
      object["textVersions"] = .array(versions)
    }
    let format = try #require(page.textVersions.first?.formats?.first)
    #expect(format.url == link)
    #expect(format.parsedURL == nil)
    #expect(format.rawFields["url"] == .string(link))
  }

  @Test("Text version endpoints encode the exact route for both identifier forms")
  func textVersionEndpointsEncodeTheExactRouteForBothIdentifierForms() throws {
    let numbered = try BillIdentifier(congress: 119, number: "1", type: .houseBill)
    let page = try CongressQuery(limit: 2, offset: 4)
    #expect(
      Endpoint.textVersions(for: numbered, page: page).path
        == "/v3/bill/119/hr/1/text?format=json&limit=2&offset=4")
    #expect(
      Endpoint.textVersions(for: numbered, page: page)
        == Endpoint.textVersions(for: try houseBill119(), page: page))
    #expect(
      Endpoint.textVersions(for: numbered).path
        == "/v3/bill/119/hr/1/text?format=json&limit=20&offset=0")
    let statute = try BillIdentifier(congress: 82, number: "677", type: BillType(rawValue: "S"))
    #expect(
      Endpoint.textVersions(for: statute).path
        == "/v3/bill/82/s/677/text?format=json&limit=20&offset=0")
    let earliest = try BillSourceIdentifier(congress: 6, number: "1", type: .houseBill)
    #expect(
      Endpoint.textVersions(for: earliest).path
        == "/v3/bill/6/hr/1/text?format=json&limit=20&offset=0")
    #expect(
      CongressRequest.textVersions(for: numbered, page: page)
        == CongressRequest.textVersions(for: try houseBill119(), page: page))
  }

  @Test("Contextual and stored text version factories infer concrete responses")
  func contextualAndStoredTextVersionFactoriesInferConcreteResponses() throws {
    struct Custom: Decodable, Sendable { let pagination: Pagination }
    let earliest = try BillSourceIdentifier(congress: 6, number: "1", type: .houseBill)
    let bill = try houseBill119()
    let page = try CongressQuery(limit: 2)
    let contextual: CongressRequest<BillTextVersionPage> = .textVersions(for: earliest)
    let stored = CongressRequest.textVersions(
      for: bill, page: page)
    let named = try CongressRequest.earliestHouseBillTextExample
    let endpoint: Endpoint<BillTextVersionPage> = .textVersions(for: earliest)
    let customEndpoint = try #require(
      Endpoint<Custom>(path: "/v3/bill/6/hr/1/text?format=json"))
    let custom = CongressRequest(endpoint: customEndpoint)
    #expect(contextual == named)
    #expect(contextual.resolution == .collection(endpoint))
    #expect(
      stored.resolution
        == .collection(.textVersions(for: bill, page: page)))
    #expect(custom.resolution == .endpoint(customEndpoint))

    let decoded = try JSONDecoder().decode(Custom.self, from: Fixture.bill6_text.data())
    #expect(decoded.pagination.count == 1)
  }
}
