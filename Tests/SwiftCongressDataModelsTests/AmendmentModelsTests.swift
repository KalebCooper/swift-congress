#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import SwiftCongressDataModels
import SwiftCongressDataTestSupport
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct AmendmentModelsTests {
  @Test("Amendment identities validate safe open codes without a SUAMDT coverage cutoff")
  func amendmentIdentitiesValidateSafeOpenCodesWithoutASUAMDTCoverageCutoff() throws {
    let identifier = try AmendmentIdentifier(
      congress: 119, number: "0003", type: .senateUnprintedAmendment)
    #expect(identifier.number == "0003" && identifier.congress == 119)
    #expect(AmendmentType.houseAmendment.rawValue == "hamdt")
    #expect(AmendmentType.senateAmendment.rawValue == "samdt")
    #expect(AmendmentType.senateUnprintedAmendment.rawValue == "suamdt")
    let future = try AmendmentIdentifier(congress: 1, number: "1", type: .init(rawValue: "FUTURE"))
    #expect(future.type.rawValue == "future")
    #expect(
      try JSONDecoder().decode(AmendmentType.self, from: Data(#""FutureCode""#.utf8)).rawValue
        == "FutureCode")
    #expect(
      try JSONEncoder().encode(AmendmentType(rawValue: "FutureCode")) == Data(#""FutureCode""#.utf8)
    )
    for number in ["", "0", "00", "-1", "1/2", "١", "1?part=2"] {
      #expect(throws: CongressInputError.invalidAmendmentIdentifier) {
        try AmendmentIdentifier(congress: 117, number: number, type: .houseAmendment)
      }
    }
    for code in ["", "samdt/1", "samdt?", "é", "samdt1"] {
      #expect(throws: CongressInputError.invalidAmendmentIdentifier) {
        try AmendmentIdentifier(congress: 117, number: "1", type: .init(rawValue: code))
      }
      #expect(throws: CongressInputError.invalidQuery) {
        try AmendmentQuery(scope: .type(congress: 117, type: .init(rawValue: code)))
      }
    }
    #expect(throws: CongressInputError.invalidAmendmentIdentifier) {
      try AmendmentIdentifier(congress: 0, number: "1", type: .houseAmendment)
    }
    #expect(throws: CongressInputError.invalidQuery) { try AmendmentQuery(scope: .congress(0)) }
    #expect(throws: CongressInputError.invalidQuery) {
      try AmendmentQuery(scope: .type(congress: -1, type: .houseAmendment))
    }
    #expect(throws: CongressInputError.invalidQuery) { try AmendmentQuery(limit: 0) }
    #expect(throws: CongressInputError.invalidQuery) { try AmendmentQuery(limit: 251) }
    #expect(throws: CongressInputError.invalidQuery) { try AmendmentQuery(offset: -1) }
    #expect(throws: CongressInputError.invalidQuery) { try BillAmendmentQuery(limit: 0) }
    #expect(throws: CongressInputError.invalidQuery) { try BillAmendmentQuery(limit: 251) }
    #expect(throws: CongressInputError.invalidQuery) { try BillAmendmentQuery(offset: -1) }
    #expect(try AmendmentQuery(limit: 250).page.limit == 250)
    #expect(try BillAmendmentQuery(limit: 250).page.limit == 250)
  }

  @Test("Amendment mutations retain unknown null duplicate and missing values")
  func amendmentMutationsRetainUnknownNullDuplicateAndMissingValues() throws {
    // Explicit mutations of official bytes, not additional captured source responses.
    let original = try JSONDecoder().decode(
      AmendmentDetail.self, from: Fixture.amendment_114_samdt_5129_detail.data())
    var fields = original.rawFields
    var record = original.amendment.rawFields
    record["type"] = .string("FutureCode")
    record["description"] = .null
    record["purpose"] = nil
    record["future"] = .boolean(true)
    record["notes"] = .array((record["notes"]?.array ?? []) + (record["notes"]?.array ?? []))
    var onBehalf = try #require(record["onBehalfOfSponsor"]?.array)
    var role = try #require(onBehalf.first?.object)
    role["type"] = .string("Future role")
    role["district"] = .null
    onBehalf[0] = .object(role)
    record["onBehalfOfSponsor"] = .array(onBehalf)
    fields["amendment"] = .object(record)
    let bytes = try JSONEncoder().encode(fields)
    let value = try JSONDecoder().decode(AmendmentDetail.self, from: bytes)
    #expect(value.amendment.type.rawValue == "FutureCode")
    #expect(value.amendment.description == nil && value.amendment.purpose == nil)
    #expect(value.amendment.rawFields["description"] == .null)
    #expect(value.amendment.rawFields["purpose"] == nil)
    #expect(value.amendment.notes?.count == 2)
    #expect(value.amendment.notes?.first == value.amendment.notes?.last)
    #expect(value.amendment.onBehalfOfSponsor?.first?.type == "Future role")
    #expect(value.amendment.onBehalfOfSponsor?.first?.rawFields["district"] == .null)
    #expect(
      try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(value)) == .object(fields)
    )
    let page = try JSONDecoder().decode(
      AmendmentPage.self, from: Fixture.amendment_97_suamdt_first.data())
    var pageFields = page.rawFields
    pageFields["amendments"] = .array(
      (pageFields["amendments"]?.array ?? []) + (pageFields["amendments"]?.array ?? []))
    let duplicate = try JSONDecoder().decode(
      AmendmentPage.self, from: JSONEncoder().encode(pageFields))
    #expect(duplicate.items == page.items + page.items)
    #expect(
      try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(duplicate))
        == .object(pageFields))
    for key in ["congress", "number", "type"] {
      for invalid: JSONValue? in [nil, .null, .boolean(true)] {
        var mutation = record
        mutation[key] = invalid
        let bytes = try JSONEncoder().encode(mutation)
        #expect(throws: DecodingError.self) {
          try JSONDecoder().decode(Amendment.self, from: bytes)
        }
        #expect(throws: DecodingError.self) {
          try JSONDecoder().decode(AmendmentSummary.self, from: bytes)
        }
      }
    }
    var nullFields = original.amendment.rawFields
    for key in [
      "actions", "amendedAmendment", "amendedBill", "amendedTreaty", "amendmentsToAmendment",
      "cosponsors", "latestAction", "notes", "onBehalfOfSponsor", "sponsors", "textVersions",
    ] {
      nullFields[key] = .null
    }
    let null = try JSONDecoder().decode(Amendment.self, from: JSONEncoder().encode(nullFields))
    #expect(
      null.actions == nil && null.amendedAmendment == nil && null.amendedBill == nil
        && null.amendedTreaty == nil)
    #expect(null.amendmentsToAmendment == nil && null.cosponsors == nil && null.latestAction == nil)
    #expect(
      null.notes == nil && null.onBehalfOfSponsor == nil && null.sponsors == nil
        && null.textVersions == nil)
    #expect(null.rawFields == nullFields)
  }

  @Test("Amendment nested fields reject incompatible source scalar types")
  func amendmentNestedFieldsRejectIncompatibleSourceScalarTypes() throws {
    let member = try JSONDecoder().decode(
      AmendmentDetail.self, from: Fixture.amendment_117_hamdt_173_detail.data()
    )
    .amendment.sponsors?.first
    var memberFields = try #require(member?.rawFields)
    memberFields["district"] = .string("12")
    let memberBytes = try JSONEncoder().encode(memberFields)
    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode(AmendmentMember.self, from: memberBytes)
    }
    let treaty = try JSONDecoder().decode(
      AmendmentDetail.self, from: Fixture.amendment_116_samdt_946_detail.data()
    )
    .amendment.amendedTreaty
    var treatyFields = try #require(treaty?.rawFields)
    treatyFields["treatyNumber"] = .string("1")
    let treatyBytes = try JSONEncoder().encode(treatyFields)
    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode(AmendmentTreaty.self, from: treatyBytes)
    }
    let amendment = try JSONDecoder().decode(
      AmendmentDetail.self, from: Fixture.amendment_117_samdt_2564_detail.data()
    ).amendment
    var cosponsors = try #require(amendment.cosponsors?.rawFields)
    cosponsors["countIncludingWithdrawnCosponsors"] = .string("3")
    let cosponsorBytes = try JSONEncoder().encode(cosponsors)
    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode(AmendmentCosponsorResource.self, from: cosponsorBytes)
    }
    var action = try #require(amendment.latestAction?.rawFields)
    action["links"] = .object([:])
    let actionBytes = try JSONEncoder().encode(action)
    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode(AmendmentAction.self, from: actionBytes)
    }
    let sparse = try JSONDecoder().decode(
      AmendmentPage.self, from: Fixture.bill_117_hr_3076_amendments_first.data())
    #expect(
      sparse.items.allSatisfy {
        $0.description == nil && $0.purpose == nil && $0.latestAction == nil
      })
  }

  @Test("Amendment queries serialize all scopes windows and bill entry points")
  func amendmentQueriesSerializeAllScopesWindowsAndBillEntryPoints() throws {
    // Documented window serialization, not a claim of live window comparison evidence.
    let scopes: [AmendmentQuery.Scope] = [
      .all, .congress(117), .type(congress: 119, type: .init(rawValue: "SUAMDT")),
    ]
    let paths = ["/v3/amendment", "/v3/amendment/117", "/v3/amendment/119/suamdt"]
    for (scope, path) in zip(scopes, paths) {
      let plain = try AmendmentQuery(scope: scope)
      #expect(Endpoint.amendments(matching: plain).path == path + "?format=json&limit=20&offset=0")
      #expect(
        CongressRequest.amendments(matching: plain).resolution
          == .collection(.amendments(matching: plain)))
      let query = try AmendmentQuery(
        fromDateTime: "2020-01-01T00:00:00+00:00", limit: 2, offset: 4,
        scope: scope, toDateTime: "2020-01-02T00:00:00Z")
      #expect(
        Endpoint.amendments(matching: query).path == path
          + "?format=json&fromDateTime=2020-01-01T00:00:00%2B00:00&limit=2&offset=4&toDateTime=2020-01-02T00:00:00Z"
      )
    }
    let identifier = try AmendmentIdentifier(
      congress: 97, number: "3", type: .senateUnprintedAmendment)
    #expect(Endpoint.amendment(identifier).path == "/v3/amendment/97/suamdt/3?format=json")
    #expect(CongressRequest.amendment(identifier).resolution == .endpoint(.amendment(identifier)))
    let bill = try BillIdentifier(congress: 117, number: "3076", type: .houseBill)
    let query = try BillAmendmentQuery(
      fromDateTime: "2020-01-01T00:00:00+00:00", limit: 2, offset: 4,
      toDateTime: "2020-01-02T00:00:00Z")
    #expect(
      Endpoint.amendments(for: bill, matching: query).path
        == "/v3/bill/117/hr/3076/amendments?format=json&fromDateTime=2020-01-01T00:00:00%2B00:00&limit=2&offset=4&toDateTime=2020-01-02T00:00:00Z"
    )
    #expect(
      Endpoint.amendments(for: bill.source, matching: query)
        == .amendments(for: bill, matching: query))
    #expect(
      CongressRequest.amendments(for: bill, matching: query).resolution
        == .collection(.amendments(for: bill, matching: query)))
  }

  @Test(
    "Amendment recorded details preserve independent targets roles dates and source disagreements")
  func amendmentRecordedDetailsPreserveIndependentTargetsRolesDatesAndSourceDisagreements() throws {
    let house = try JSONDecoder().decode(
      AmendmentDetail.self, from: Fixture.amendment_117_hamdt_173_detail.data()
    ).amendment
    #expect(
      house.amendedBill?.number == "3076" && house.amendedAmendment == nil
        && house.amendedTreaty == nil)
    #expect(house.sponsors?.first?.district == 12)
    #expect(house.description != nil && house.purpose == nil)
    #expect(house.actions?.count == 7 && house.textVersions?.count == 1)
    let senate = try JSONDecoder().decode(
      AmendmentDetail.self, from: Fixture.amendment_117_samdt_2564_detail.data()
    ).amendment
    #expect(senate.amendedBill?.number == "3684" && senate.amendedAmendment?.number == "2137")
    #expect(
      senate.cosponsors?.count == 3 && senate.cosponsors?.countIncludingWithdrawnCosponsors == 3)
    #expect(senate.sponsors?.first?.district == nil)
    let treaty = try JSONDecoder().decode(
      AmendmentDetail.self, from: Fixture.amendment_116_samdt_946_detail.data()
    ).amendment
    #expect(treaty.amendedTreaty?.congress == 116 && treaty.amendedTreaty?.treatyNumber == 1)
    #expect(treaty.amendedBill == nil && treaty.amendedAmendment == nil)
    #expect(treaty.amendmentsToAmendment?.count == 1)
    let roles = try JSONDecoder().decode(
      AmendmentDetail.self, from: Fixture.amendment_114_samdt_5129_detail.data()
    ).amendment
    #expect(
      roles.onBehalfOfSponsor?.map(\.type) == ["Submitted on behalf of", "Proposed on behalf of"])
    #expect(roles.onBehalfOfSponsor?.map(\.bioguideId) == ["M000355", "B001236"])
    #expect(roles.sponsors?.map(\.bioguideId) == ["E000295"])
    #expect(
      roles.submittedDate == "2016-12-05T05:00:00Z" && roles.proposedDate == "2016-12-10T05:00:00Z")
    #expect(roles.notes?.first?.text?.contains("vitiated") == true)
    let parent = try JSONDecoder().decode(
      AmendmentDetail.self, from: Fixture.amendment_117_samdt_2137_detail.data()
    ).amendment
    #expect(parent.amendmentsToAmendment?.count == 507)
    #expect(parent.latestAction?.links?.map(\.name) == ["Record Vote Number: 312", "SA 2137"])
    #expect(parent.latestAction?.links?.first?.url?.contains("vote_117_1_00312.htm") == true)
    let historical = try JSONDecoder().decode(
      AmendmentDetail.self, from: Fixture.amendment_97_suamdt_3_detail.data()
    ).amendment
    #expect(historical.number == "3" && historical.type.rawValue == "SUAMDT")
    #expect(historical.latestAction?.links?.first?.name == "SP 2")
    #expect(historical.latestAction?.links?.first?.url?.hasSuffix("/senate-amendment/2") == true)
    let referenced = try #require(senate.amendedAmendment)
    let identifier = try AmendmentIdentifier(
      congress: referenced.congress, number: referenced.number, type: referenced.type)
    #expect(Endpoint.amendment(identifier).path == "/v3/amendment/117/samdt/2137?format=json")
  }

  @Test(
    "Amendments preserve every captured field and response envelope",
    arguments: [
      Fixture.amendment_inventory_first,
      Fixture.amendment_117_inventory_first,
      Fixture.amendment_97_suamdt_first,
      Fixture.amendment_117_hamdt_173_detail,
      Fixture.amendment_117_samdt_2564_detail,
      Fixture.amendment_116_samdt_946_detail,
      Fixture.bill_117_hr_3076_amendments_first,
      Fixture.bill_117_hr_3076_amendments_next,
      Fixture.amendment_97_suamdt_3_detail,
      Fixture.amendment_114_samdt_5129_detail,
      Fixture.amendment_117_samdt_2137_detail,
      Fixture.bill_117_hr_3076_amendments_terminal,
    ])
  func amendmentsPreserveEveryCapturedFieldAndResponseEnvelope(fixture: Fixture) throws {
    let bytes = try fixture.data()
    let raw = try JSONDecoder().decode([String: JSONValue].self, from: bytes)
    let encoded: Data
    if raw["amendment"] != nil {
      let detail = try JSONDecoder().decode(AmendmentDetail.self, from: bytes)
      #expect(detail.request == raw["request"])
      let amendment = detail.amendment
      #expect(amendment.rawFields == raw["amendment"]?.object)
      #expect(amendment.congress == amendment.rawFields["congress"]?.integer)
      #expect(amendment.number == amendment.rawFields["number"]?.string)
      #expect(amendment.description == amendment.rawFields["description"]?.string)
      #expect(amendment.purpose == amendment.rawFields["purpose"]?.string)
      #expect(amendment.chamber == amendment.rawFields["chamber"]?.string)
      #expect(amendment.submittedDate == amendment.rawFields["submittedDate"]?.string)
      #expect(amendment.proposedDate == amendment.rawFields["proposedDate"]?.string)
      #expect(amendment.updateDate == amendment.rawFields["updateDate"]?.string)
      #expect(amendment.url == amendment.rawFields["url"]?.string)
      #expect(amendment.type.rawValue == amendment.rawFields["type"]?.string)
      #expect(amendment.actions?.rawFields == amendment.rawFields["actions"]?.object)
      #expect(
        amendment.amendedAmendment?.rawFields == amendment.rawFields["amendedAmendment"]?.object)
      #expect(amendment.amendedBill?.rawFields == amendment.rawFields["amendedBill"]?.object)
      #expect(amendment.amendedTreaty?.rawFields == amendment.rawFields["amendedTreaty"]?.object)
      #expect(
        amendment.amendmentsToAmendment?.rawFields
          == amendment.rawFields["amendmentsToAmendment"]?.object)
      #expect(amendment.cosponsors?.rawFields == amendment.rawFields["cosponsors"]?.object)
      #expect(amendment.latestAction?.rawFields == amendment.rawFields["latestAction"]?.object)
      #expect(amendment.textVersions?.rawFields == amendment.rawFields["textVersions"]?.object)
      #expect(
        amendment.notes?.map(\.rawFields)
          == amendment.rawFields["notes"]?.array?.compactMap(\.object))
      #expect(
        amendment.onBehalfOfSponsor?.map(\.rawFields)
          == amendment.rawFields["onBehalfOfSponsor"]?.array?.compactMap(\.object))
      #expect(
        amendment.sponsors?.map(\.rawFields)
          == amendment.rawFields["sponsors"]?.array?.compactMap(\.object))
      for member in (amendment.sponsors ?? []) + (amendment.onBehalfOfSponsor ?? []) {
        #expect(member.bioguideId == member.rawFields["bioguideId"]?.string)
        #expect(member.district == member.rawFields["district"]?.integer)
        #expect(member.firstName == member.rawFields["firstName"]?.string)
        #expect(member.fullName == member.rawFields["fullName"]?.string)
        #expect(member.lastName == member.rawFields["lastName"]?.string)
        #expect(member.middleName == member.rawFields["middleName"]?.string)
        #expect(member.party == member.rawFields["party"]?.string)
        #expect(member.state == member.rawFields["state"]?.string)
        #expect(member.type == member.rawFields["type"]?.string)
        #expect(member.url == member.rawFields["url"]?.string)
      }
      if let treaty = amendment.amendedTreaty {
        #expect(treaty.congress == treaty.rawFields["congress"]?.integer)
        #expect(treaty.treatyNumber == treaty.rawFields["treatyNumber"]?.integer)
        #expect(treaty.url == treaty.rawFields["url"]?.string)
      }
      if let resource = amendment.cosponsors {
        #expect(resource.count == resource.rawFields["count"]?.integer)
        #expect(
          resource.countIncludingWithdrawnCosponsors
            == resource.rawFields["countIncludingWithdrawnCosponsors"]?.integer)
        #expect(resource.url == resource.rawFields["url"]?.string)
      }
      for resource in [amendment.actions, amendment.amendmentsToAmendment, amendment.textVersions]
        .compactMap({ $0 })
      {
        #expect(resource.count == resource.rawFields["count"]?.integer)
        #expect(resource.url == resource.rawFields["url"]?.string)
      }
      for note in amendment.notes ?? [] { #expect(note.text == note.rawFields["text"]?.string) }
      if let target = amendment.amendedAmendment { try verifySummary(target) }
      if let action = amendment.latestAction { verifyAction(action) }
      encoded = try JSONEncoder().encode(detail)
    } else {
      let page = try JSONDecoder().decode(AmendmentPage.self, from: bytes)
      #expect(page.request == raw["request"])
      #expect(page.items == page.amendments)
      #expect(page.items.map(\.rawFields) == raw["amendments"]?.array?.compactMap(\.object))
      for item in page.items { try verifySummary(item) }
      encoded = try JSONEncoder().encode(page)
    }
    #expect(try JSONDecoder().decode(JSONValue.self, from: encoded) == .object(raw))
  }

  private func verifyAction(_ action: AmendmentAction) {
    #expect(action.actionDate == action.rawFields["actionDate"]?.string)
    #expect(action.actionTime == action.rawFields["actionTime"]?.string)
    #expect(action.text == action.rawFields["text"]?.string)
    #expect(
      action.links?.map(\.rawFields) == action.rawFields["links"]?.array?.compactMap(\.object))
    for link in action.links ?? [] {
      #expect(link.name == link.rawFields["name"]?.string)
      #expect(link.url == link.rawFields["url"]?.string)
    }
  }

  private func verifySummary(_ record: AmendmentSummary) throws {
    #expect(record.congress == record.rawFields["congress"]?.integer)
    #expect(record.number == record.rawFields["number"]?.string)
    #expect(record.type.rawValue == record.rawFields["type"]?.string)
    #expect(record.description == record.rawFields["description"]?.string)
    #expect(record.purpose == record.rawFields["purpose"]?.string)
    #expect(record.updateDate == record.rawFields["updateDate"]?.string)
    #expect(record.url == record.rawFields["url"]?.string)
    #expect(record.latestAction?.rawFields == record.rawFields["latestAction"]?.object)
    if let action = record.latestAction { verifyAction(action) }
    #expect(
      try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(record))
        == .object(record.rawFields))
  }
}
