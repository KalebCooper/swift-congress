#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import SwiftCongressDataModels
import SwiftCongressDataTestSupport
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct BillRelationshipsModelsTests {
  @Test("Association queries preserve both bill identities and encoded date windows")
  func associationQueriesPreserveBothBillIdentitiesAndEncodedDateWindows() throws {
    let bill = try BillIdentifier(congress: 119, number: "5", type: .senateBill)
    let page = try CongressQuery(limit: 2, offset: 4)
    let related = Endpoint.relatedBills(for: bill, page: page)
    #expect(related.path == "/v3/bill/119/s/5/relatedbills?format=json&limit=2&offset=4")
    #expect(related == Endpoint.relatedBills(for: bill.source, page: page))
    #expect(CongressRequest.relatedBills(for: bill, page: page).resolution == .collection(related))
    let committees = Endpoint.committees(for: bill, page: page)
    #expect(committees.path == "/v3/bill/119/s/5/committees?format=json&limit=2&offset=4")
    #expect(committees == Endpoint.committees(for: bill.source, page: page))
    #expect(CongressRequest.committees(for: bill, page: page).resolution == .collection(committees))
    let query = try BillSubjectQuery(
      fromDateTime: "raw+lower&x=1", limit: 250, offset: 4, toDateTime: "upper?")
    let subjects = Endpoint.subjects(for: bill, matching: query)
    let components = try #require(URLComponents(string: "https://api.congress.gov" + subjects.path))
    let values = Dictionary(
      uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") })
    #expect(
      values == [
        "format": "json", "fromDateTime": "raw+lower&x=1", "limit": "250", "offset": "4",
        "toDateTime": "upper?",
      ])
    #expect(subjects.path.contains("%2B"))
    #expect(subjects == Endpoint.subjects(for: bill.source, matching: query))
    #expect(
      CongressRequest.subjects(for: bill, matching: query).resolution == .collection(subjects))
    #expect(CongressRequest(endpoint: subjects).resolution == .endpoint(subjects))
    let historical = try BillSourceIdentifier(congress: 6, number: "1", type: .houseBill)
    #expect(
      Endpoint.subjects(for: historical, matching: try BillSubjectQuery()).path
        == "/v3/bill/6/hr/1/subjects?format=json&limit=20&offset=0")
    #expect(
      Endpoint.relatedBills(for: historical).path
        == "/v3/bill/6/hr/1/relatedbills?format=json&limit=20&offset=0")
    #expect(
      Endpoint.committees(for: historical).path
        == "/v3/bill/6/hr/1/committees?format=json&limit=20&offset=0")
    #expect(throws: CongressInputError.invalidQuery) { try BillSubjectQuery(limit: 0) }
    #expect(throws: CongressInputError.invalidQuery) { try BillSubjectQuery(limit: 251) }
    #expect(throws: CongressInputError.invalidQuery) { try BillSubjectQuery(offset: -1) }
  }

  @Test("Association records preserve authorities committee hierarchy and activity order")
  func associationRecordsPreserveAuthoritiesCommitteeHierarchyAndActivityOrder() throws {
    let first = try JSONDecoder().decode(
      RelatedBillPage.self, from: Fixture.bill119_s5_related_first.data())
    let last = try JSONDecoder().decode(
      RelatedBillPage.self, from: Fixture.bill119_s5_related_terminal.data())
    #expect(first.items.map(\.number) == [149, 29])
    #expect((first.items + last.items).filter { $0.number == 149 }.count == 2)
    #expect(first.items[0].relationshipDetails?.map(\.identifiedBy) == ["CRS", "CRS"])
    #expect(
      first.items[0].relationshipDetails?.map(\.type) == [
        "Public law contains the text", "Related bill",
      ])
    #expect(
      last.items.flatMap { $0.relationshipDetails ?? [] }.contains { $0.identifiedBy == "House" })
    #expect(first.items[0].latestAction?.actionDate == "2025-01-17")
    let committees = try JSONDecoder().decode(
      BillCommitteePage.self, from: Fixture.bill117_hr3076_committees_first.data())
    #expect(committees.items.map(\.systemCode) == ["hswm00", "hsif00"])
    #expect(committees.items[0].activities?.map(\.name) == ["Discharged From", "Referred To"])
    let child = try #require(committees.items[1].subcommittees?.first)
    #expect(child.name == "Health Subcommittee")
    #expect(child.systemCode == "hsif14")
    #expect(child.activities?.first?.name == "Referred to")
    #expect(child.rawFields["chamber"] == nil)
    #expect(child.rawFields["type"] == nil)
    try roundTrip(child)
    for row in first.items + last.items {
      try roundTrip(row)
      for detail in row.relationshipDetails ?? [] { try roundTrip(detail) }
    }
    for row in committees.items {
      try roundTrip(row)
      for activity in row.activities ?? [] { try roundTrip(activity) }
    }
  }

  @Test("Consumer collections on subject routes retain strict item count behavior")
  func consumerCollectionsOnSubjectRoutesRetainStrictItemCountBehavior() throws {
    struct Consumer: CongressCollection {
      let items: [BillSubject]
      let pagination: Pagination
      init(from decoder: any Decoder) throws {
        let page = try BillSubjectPage(from: decoder)
        items = page.items
        pagination = page.pagination
      }
    }
    let bytes = try Fixture.bill119_s5_subjects_policy_first.data()
    let page = try JSONDecoder().decode(Consumer.self, from: bytes)
    let source = try BillSourceIdentifier(congress: 119, number: "5", type: .senateBill)
    let path = try Endpoint.subjects(for: source, matching: BillSubjectQuery(limit: 1)).path
    let endpoint = try #require(Endpoint<Consumer>(path: path))
    #expect(throws: CongressPaginationError.invalidContinuation) {
      try CongressContinuation.next(after: page, endpoint: endpoint)
    }
    let ordinary = try JSONDecoder().decode(
      Consumer.self, from: Fixture.bill119_s5_subjects_first.data())
    let ordinaryEndpoint = try #require(
      Endpoint<Consumer>(path: path.replacingOccurrences(of: "limit=1", with: "limit=6")))
    #expect(throws: CongressPaginationError.invalidContinuation) {
      try CongressContinuation.next(after: ordinary, endpoint: ordinaryEndpoint)
    }
  }

  @Test("Every recorded association envelope round trips all source fields")
  func everyRecordedAssociationEnvelopeRoundTripsAllSourceFields() throws {
    for fixture in [Fixture.bill119_s5_related_first, .bill119_s5_related_terminal] {
      try fixtureRoundTrip(RelatedBillPage.self, fixture: fixture)
    }
    for fixture in [Fixture.bill117_hr3076_committees_first, .bill117_hr3076_committees_terminal] {
      try fixtureRoundTrip(BillCommitteePage.self, fixture: fixture)
    }
    for fixture in [
      Fixture.bill119_s5_subjects_first, .bill119_s5_subjects_terminal,
      .bill119_s5_subjects_policy_first, .bill119_s5_subjects_policy_next,
      .bill119_s5_subjects_policy_window, .bill82_s677_subjects_sparse,
      .bill93_hjres1_subjects_historical,
    ] {
      try fixtureRoundTrip(BillSubjectPage.self, fixture: fixture)
    }
  }

  @Test("Nested association mutations retain unknown null absent and duplicate values")
  func nestedAssociationMutationsRetainUnknownNullAbsentAndDuplicateValues() throws {
    // Labeled mutations exercise preservation; they are not additional provider evidence.
    let relationship = try JSONDecoder().decode(
      BillRelationshipDetail.self,
      from: Data(#"{"identifiedBy":null,"type":"Future relationship","unknown":[null]}"#.utf8))
    #expect(relationship.identifiedBy == nil)
    #expect(relationship.rawFields["identifiedBy"] == .null)
    #expect(relationship.type == "Future relationship")
    try roundTrip(relationship)
    let activity = try JSONDecoder().decode(
      BillCommitteeActivity.self,
      from: Data(#"{"date":null,"name":"Future action","extra":42}"#.utf8))
    #expect(activity.date == nil)
    try roundTrip(activity)
    var row = try JSONDecoder().decode(
      RelatedBillPage.self, from: Fixture.bill119_s5_related_first.data()
    ).items[0].rawFields
    row["relationshipDetails"] = .array([
      .object(relationship.rawFields), .object(relationship.rawFields),
    ])
    row["title"] = .null
    row["type"] = .string("Future bill kind")
    let related = try JSONDecoder().decode(RelatedBill.self, from: JSONEncoder().encode(row))
    #expect(related.title == nil)
    #expect(related.type == "Future bill kind")
    #expect(related.relationshipDetails == [relationship, relationship])
    try roundTrip(related)
    row["number"] = .string("149")
    #expect(throws: (any Error).self) {
      try JSONDecoder().decode(RelatedBill.self, from: JSONEncoder().encode(row))
    }
    for null in [false, true] {
      var object = try JSONDecoder().decode(
        [String: JSONValue].self, from: Fixture.bill119_s5_subjects_first.data())
      var subjects = try #require(object["subjects"]?.object)
      if null { subjects["policyArea"] = .null } else { subjects.removeValue(forKey: "policyArea") }
      subjects["unknown"] = .array([.null])
      object["subjects"] = .object(subjects)
      let page = try JSONDecoder().decode(BillSubjectPage.self, from: JSONEncoder().encode(object))
      #expect(page.policyArea == nil)
      #expect(page.rawFields["subjects"]?.object?["policyArea"] == (null ? .null : nil))
      #expect(
        try JSONDecoder().decode([String: JSONValue].self, from: JSONEncoder().encode(page))
          == object)
    }
    let subcommittee = try JSONDecoder().decode(
      BillSubcommittee.self, from: Data(#"{"activities":null,"name":null,"unknown":[]}"#.utf8))
    #expect(subcommittee.activities == nil)
    #expect(subcommittee.rawFields["activities"] == .null)
    #expect(subcommittee.rawFields["systemCode"] == nil)
    try roundTrip(subcommittee)
    let committee = try JSONDecoder().decode(
      BillCommittee.self,
      from: Data(
        #"{"activities":[],"chamber":"Future chamber","subcommittees":null,"type":null}"#.utf8))
    #expect(committee.activities == [])
    #expect(committee.chamber == "Future chamber")
    #expect(committee.subcommittees == nil)
    try roundTrip(committee)
  }

  @Test("Subject continuation counts policy records without fabricating legislative items")
  func subjectContinuationCountsPolicyRecordsWithoutFabricatingLegislativeItems() throws {
    let source = try BillSourceIdentifier(congress: 119, number: "5", type: .senateBill)
    var endpoint = try Endpoint.subjects(for: source, matching: BillSubjectQuery(limit: 6))
    let first = try JSONDecoder().decode(
      BillSubjectPage.self, from: Fixture.bill119_s5_subjects_first.data())
    #expect(first.items.count == 5)
    #expect(first.policyArea?.name == "Immigration")
    #expect(first.pagination.count == 12)
    let continuation = try CongressContinuation.next(after: first, endpoint: endpoint)
    endpoint = try #require(continuation)
    #expect(endpoint.path == "/v3/bill/119/s/5/subjects?offset=6&limit=6&format=json")
    let terminal = try JSONDecoder().decode(
      BillSubjectPage.self, from: Fixture.bill119_s5_subjects_terminal.data())
    #expect(terminal.items.count == 6)
    #expect(terminal.policyArea == nil)
    #expect(try CongressContinuation.next(after: terminal, endpoint: endpoint) == nil)
    let policy = try JSONDecoder().decode(
      BillSubjectPage.self, from: Fixture.bill119_s5_subjects_policy_first.data())
    #expect(policy.items.isEmpty)
    let initial = try Endpoint.subjects(for: source, matching: BillSubjectQuery(limit: 1))
    let policyContinuation = try CongressContinuation.next(after: policy, endpoint: initial)
    let next = try #require(policyContinuation)
    #expect(next.path == "/v3/bill/119/s/5/subjects?offset=1&limit=1&format=json")
    let nextPage = try JSONDecoder().decode(
      BillSubjectPage.self, from: Fixture.bill119_s5_subjects_policy_next.data())
    #expect(nextPage.items.count == 1)
    let followingContinuation = try CongressContinuation.next(after: nextPage, endpoint: next)
    let later = try #require(followingContinuation)
    #expect(later.path == "/v3/bill/119/s/5/subjects?offset=2&limit=1&format=json")
    let overflow = try Endpoint.subjects(
      for: source, matching: BillSubjectQuery(limit: 1, offset: Int.max))
    #expect(throws: CongressPaginationError.invalidContinuation) {
      try CongressContinuation.next(after: policy, endpoint: overflow)
    }
  }

  @Test("Subject historical sparse and filtered policy only terminals retain raw totals")
  func subjectHistoricalSparseAndFilteredPolicyOnlyTerminalsRetainRawTotals() throws {
    for (fixture, congress, number, type, count, items) in [
      (Fixture.bill93_hjres1_subjects_historical, 93, "1", BillType.houseJointResolution, 5, 4),
      (.bill82_s677_subjects_sparse, 82, "677", .senateBill, 0, 0),
      (.bill119_s5_subjects_policy_window, 119, "5", .senateBill, 1, 0),
    ] {
      let page = try JSONDecoder().decode(BillSubjectPage.self, from: fixture.data())
      #expect(page.pagination.count == count)
      #expect(page.items.count == items)
      let source = try BillSourceIdentifier(congress: congress, number: number, type: type)
      let query = try BillSubjectQuery(limit: 250)
      #expect(
        try CongressContinuation.next(
          after: page, endpoint: .subjects(for: source, matching: query)) == nil)
      for subject in page.items { try roundTrip(subject) }
      if let policy = page.policyArea { try roundTrip(policy) }
    }
  }

  private func fixtureRoundTrip<Value: Codable>(_ type: Value.Type, fixture: Fixture) throws {
    let bytes = try fixture.data()
    let value = try JSONDecoder().decode(type, from: bytes)
    #expect(
      try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(value))
        == JSONDecoder().decode(JSONValue.self, from: bytes))
  }

  private func roundTrip<Value: Codable & Equatable>(_ value: Value) throws {
    #expect(try JSONDecoder().decode(Value.self, from: JSONEncoder().encode(value)) == value)
  }
}
