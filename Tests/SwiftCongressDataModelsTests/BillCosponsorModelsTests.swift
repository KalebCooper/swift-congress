#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import SwiftCongressDataModels
import SwiftCongressDataTestSupport
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct BillCosponsorModelsTests {
  @Test("Cosponsor count policy is limited to built in cosponsor pages")
  func cosponsorCountPolicyIsLimitedToBuiltInCosponsorPages() throws {
    struct ConsumerPage: CongressCollection {
      let cosponsors: [BillCosponsor]
      let pagination: Pagination
      var items: [BillCosponsor] { cosponsors }
    }
    let bytes = try Fixture.bill117_s3580_cosponsors_next.data()
    let page = try JSONDecoder().decode(BillCosponsorPage.self, from: bytes)
    let bill = try BillSourceIdentifier(congress: 117, number: "3580", type: .senateBill)
    let endpoint = try Endpoint.cosponsors(
      for: bill, matching: BillCosponsorQuery(limit: 15, offset: 15))
    #expect(
      try CongressContinuation.next(after: page, endpoint: endpoint)?.path.contains("offset=30")
        == true)
    let consumer = try JSONDecoder().decode(ConsumerPage.self, from: bytes)
    let custom = try #require(Endpoint<ConsumerPage>(path: endpoint.path))
    #expect(throws: CongressPaginationError.invalidContinuation) {
      try CongressContinuation.next(after: consumer, endpoint: custom)
    }
    // A labeled mutation on a different built-in collection must not opt into inclusive counts.
    var other = try JSONDecoder().decode(
      [String: JSONValue].self, from: Fixture.bill119_summaries_first.data())
    var pagination = try #require(other["pagination"]?.object)
    pagination["count"] = .number(2)
    pagination["countIncludingWithdrawnCosponsors"] = .number(5)
    other["pagination"] = .object(pagination)
    let summary = try JSONDecoder().decode(BillSummaryPage.self, from: JSONEncoder().encode(other))
    let summaryBill = try BillSourceIdentifier(congress: 119, number: "1", type: .houseBill)
    let summaryEndpoint = try Endpoint.summaries(for: summaryBill, page: CongressQuery(limit: 2))
    #expect(throws: CongressPaginationError.invalidContinuation) {
      try CongressContinuation.next(after: summary, endpoint: summaryEndpoint)
    }
    let text = try JSONDecoder().decode(
      BillTextVersionPage.self, from: Fixture.bill119_text_first.data())
    let textEndpoint = try Endpoint.textVersions(for: summaryBill, page: CongressQuery(limit: 2))
    #expect(try CongressContinuation.next(after: text, endpoint: textEndpoint) != nil)
  }

  @Test("Cosponsor missing null and unknown fields preserve source distinctions")
  func cosponsorMissingNullAndUnknownFieldsPreserveSourceDistinctions() throws {
    // Labeled mutations establish decoder behavior, not additional provider evidence.
    let page = try JSONDecoder().decode(
      BillCosponsorPage.self, from: Fixture.bill119_hr22_cosponsors_house.data())
    var fields = try #require(page.items.first?.rawFields)
    fields["district"] = .null
    fields["isOriginalCosponsor"] = .null
    fields["party"] = .string("FUTURE")
    fields["sponsorshipDate"] = .string("unparsed")
    fields["unknown"] = .array([.null])
    fields.removeValue(forKey: "firstName")
    let row = try JSONDecoder().decode(BillCosponsor.self, from: JSONEncoder().encode(fields))
    #expect(row.district == nil)
    #expect(row.firstName == nil)
    #expect(row.isOriginalCosponsor == nil)
    #expect(row.party == "FUTURE")
    #expect(row.sponsorshipDate == "unparsed")
    #expect(row.rawFields["district"] == .null)
    #expect(row.rawFields["firstName"] == nil)
    #expect(
      try JSONDecoder().decode([String: JSONValue].self, from: JSONEncoder().encode(row)) == fields)
    fields["district"] = .string("2")
    #expect(throws: (any Error).self) {
      try JSONDecoder().decode(BillCosponsor.self, from: JSONEncoder().encode(fields))
    }
    fields["district"] = .number(2)
    fields["isOriginalCosponsor"] = .string("false")
    #expect(throws: (any Error).self) {
      try JSONDecoder().decode(BillCosponsor.self, from: JSONEncoder().encode(fields))
    }
    fields.removeValue(forKey: "isOriginalCosponsor")
    fields.removeValue(forKey: "bioguideId")
    #expect(throws: (any Error).self) {
      try JSONDecoder().decode(BillCosponsor.self, from: JSONEncoder().encode(fields))
    }
  }

  @Test("Cosponsor queries preserve timestamps bounds sorting and both bill identifiers")
  func cosponsorQueriesPreserveTimestampsBoundsSortingAndBothBillIdentifiers() throws {
    let bill = try BillIdentifier(congress: 117, number: "3580", type: .senateBill)
    let query = try BillCosponsorQuery(
      fromDateTime: "raw+value", limit: 250, offset: 5, sort: .updateDateAscending,
      toDateTime: "later")
    let endpoint = Endpoint.cosponsors(for: bill, matching: query)
    #expect(
      endpoint.path
        == "/v3/bill/117/s/3580/cosponsors?format=json&fromDateTime=raw%2Bvalue&limit=250&offset=5&sort=updateDate%2Basc&toDateTime=later"
    )
    #expect(Endpoint.cosponsors(for: bill.source, matching: query) == endpoint)
    #expect(
      CongressRequest.cosponsors(for: bill, matching: query).resolution == .collection(endpoint))
    #expect(
      CongressRequest.cosponsors(for: bill.source, matching: query).resolution
        == .collection(endpoint))
    let descending = try BillCosponsorQuery(sort: .updateDateDescending)
    #expect(
      Endpoint.cosponsors(for: bill, matching: descending).path.contains("sort=updateDate%2Bdesc"))
    let defaults = try BillCosponsorQuery()
    #expect(
      Endpoint.cosponsors(for: bill, matching: defaults).path
        == "/v3/bill/117/s/3580/cosponsors?format=json&limit=20&offset=0")
    #expect(throws: CongressInputError.invalidQuery) { try BillCosponsorQuery(limit: 0) }
    #expect(throws: CongressInputError.invalidQuery) { try BillCosponsorQuery(limit: 251) }
    #expect(throws: CongressInputError.invalidQuery) { try BillCosponsorQuery(offset: -1) }
  }

  @Test("Inclusive counts fall back only when missing or null")
  func inclusiveCountsFallBackOnlyWhenMissingOrNull() throws {
    let bill = try BillSourceIdentifier(congress: 119, number: "1", type: .houseBill)
    let endpoint = try Endpoint.cosponsors(for: bill, matching: BillCosponsorQuery(limit: 2))
    for null in [false, true] {
      var fields = try JSONDecoder().decode(
        [String: JSONValue].self, from: Fixture.bill119_hr1_cosponsors_current.data())
      var pagination = try #require(fields["pagination"]?.object)
      if null {
        pagination["countIncludingWithdrawnCosponsors"] = .null
      } else {
        pagination.removeValue(forKey: "countIncludingWithdrawnCosponsors")
      }
      fields["pagination"] = .object(pagination)
      fields["future"] = .boolean(true)
      fields["request"] = .null
      let page = try JSONDecoder().decode(
        BillCosponsorPage.self, from: JSONEncoder().encode(fields))
      #expect(page.countIncludingWithdrawnCosponsors == nil)
      #expect(page.request == nil)
      #expect(try CongressContinuation.next(after: page, endpoint: endpoint) == nil)
      #expect(
        try JSONDecoder().decode([String: JSONValue].self, from: JSONEncoder().encode(page))
          == fields)
      fields.removeValue(forKey: "cosponsors")
      #expect(throws: (any Error).self) {
        try JSONDecoder().decode(BillCosponsorPage.self, from: JSONEncoder().encode(fields))
      }
    }
    var fields = try JSONDecoder().decode(
      [String: JSONValue].self, from: Fixture.bill119_hr1_cosponsors_current.data())
    fields["pagination"] = .object([
      "count": .number(0), "countIncludingWithdrawnCosponsors": .string("0"),
    ])
    #expect(throws: (any Error).self) {
      try JSONDecoder().decode(BillCosponsorPage.self, from: JSONEncoder().encode(fields))
    }
    for null in [false, true] {
      var boundary = try JSONDecoder().decode(
        [String: JSONValue].self, from: Fixture.bill117_s3580_cosponsors_next.data())
      var counts = try #require(boundary["pagination"]?.object)
      if null {
        counts["countIncludingWithdrawnCosponsors"] = .null
      } else {
        counts.removeValue(forKey: "countIncludingWithdrawnCosponsors")
      }
      boundary["pagination"] = .object(counts)
      let page = try JSONDecoder().decode(
        BillCosponsorPage.self, from: JSONEncoder().encode(boundary))
      let source = try BillSourceIdentifier(congress: 117, number: "3580", type: .senateBill)
      let current = try Endpoint.cosponsors(
        for: source, matching: BillCosponsorQuery(limit: 15, offset: 15))
      #expect(throws: CongressPaginationError.invalidContinuation) {
        try CongressContinuation.next(after: page, endpoint: current)
      }
    }

  }

  @Test("Recorded cosponsor fields distinguish withdrawals and absent Senate districts")
  func recordedCosponsorFieldsDistinguishWithdrawalsAndAbsentSenateDistricts() throws {
    let senate = try JSONDecoder().decode(
      BillCosponsorPage.self, from: Fixture.bill117_s3580_cosponsors_next.data())
    let withdrawn = try #require(senate.items.first { $0.bioguideId == "H000601" })
    #expect(withdrawn.sponsorshipDate == "2022-03-15")
    #expect(withdrawn.sponsorshipWithdrawnDate == "2022-03-21")
    #expect(withdrawn.isOriginalCosponsor == false)
    #expect(senate.items.allSatisfy { $0.district == nil })
    #expect(senate.pagination.count == 30)
    #expect(senate.countIncludingWithdrawnCosponsors == 31)
    let house = try JSONDecoder().decode(
      BillCosponsorPage.self, from: Fixture.bill119_hr22_cosponsors_house.data())
    #expect(house.items.first?.district == 2)
    #expect(house.items.first?.bioguideId == "G000597")
  }

  @Test(
    "Recorded cosponsor pages round trip every source field",
    arguments: [
      Fixture.bill117_s3580_cosponsors_first, Fixture.bill117_s3580_cosponsors_next,
      Fixture.bill117_s3580_cosponsors_terminal, Fixture.bill119_hr1_cosponsors_current,
      Fixture.bill119_hr22_cosponsors_house,
    ])
  func recordedCosponsorPagesRoundTripEverySourceField(fixture: Fixture) throws {
    let bytes = try fixture.data()
    let page = try JSONDecoder().decode(BillCosponsorPage.self, from: bytes)
    #expect(page.items == page.cosponsors)
    for row in page.items {
      #expect(row.bioguideId == row.rawFields["bioguideId"]?.string)
      #expect(row.district == row.rawFields["district"]?.integer)
      #expect(
        row.isOriginalCosponsor.map(JSONValue.boolean) == row.rawFields["isOriginalCosponsor"])
      #expect(row.firstName == row.rawFields["firstName"]?.string)
      #expect(row.fullName == row.rawFields["fullName"]?.string)
      #expect(row.lastName == row.rawFields["lastName"]?.string)
      #expect(row.middleName == row.rawFields["middleName"]?.string)
      #expect(row.party == row.rawFields["party"]?.string)
      #expect(row.sponsorshipDate == row.rawFields["sponsorshipDate"]?.string)
      #expect(row.sponsorshipWithdrawnDate == row.rawFields["sponsorshipWithdrawnDate"]?.string)
      #expect(row.state == row.rawFields["state"]?.string)
      #expect(row.url == row.rawFields["url"]?.string)
    }
    #expect(
      try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(page))
        == JSONDecoder().decode(JSONValue.self, from: bytes))
  }
}
