import Foundation
import SwiftCongressHouseVotesModels
import SwiftCongressHouseVotesTestSupport
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct HouseProjectionTests {
  @Test("A quorum call publishes present and not voting totals in its aggregate row")
  func aQuorumCallPublishesPresentAndNotVotingTotalsInItsAggregateRow() throws {
    let tallies = try #require(
      try decode(.house1990, "https://clerk.house.gov/evs/1990/roll001.xml").tallies)
    #expect(tallies.byCandidate.isEmpty)
    #expect(tallies.byVote.count == 1)
    let row = try #require(tallies.byVote.first)
    #expect(
      row.counts.map(\.name) == ["yea-total", "nay-total", "present-total", "not-voting-total"])
    #expect(row.present?.value == 376)
    #expect(row.notVoting?.value == 54)
    #expect(row.yea?.value == 0)
    #expect(row.nay?.value == 0)
    #expect(row.aye == nil)
    #expect(row.no == nil)
    #expect(tallies.byParty.map(\.party) == ["Republican", "Democratic", "Independent"])
    #expect(tallies.byParty.map { $0.counts.present?.value } == [151, 225, 0])
    #expect(tallies.byParty.map { $0.counts.notVoting?.value } == [24, 30, 0])
  }

  @Test("A historical Aye and No vote keeps the source yea and nay element names")
  func aHistoricalAyeAndNoVoteKeepsTheSourceYeaAndNayElementNames() throws {
    let tallies = try #require(
      try decode(.house1990_vote, "https://clerk.house.gov/evs/1990/roll010.xml").tallies)
    let row = try #require(tallies.byVote.first)
    #expect(row.yea?.value == 156)
    #expect(row.nay?.value == 265)
    #expect(row.present?.value == 0)
    #expect(row.notVoting?.value == 10)
    #expect(row.aye == nil)
    #expect(row.no == nil)
    let header = try #require(tallies.rawNode.child("totals-by-party-header"))
    #expect(header.child("yea-header")?.text == "Ayes")
    #expect(header.child("nay-header")?.text == "Noes")
    let republican = try #require(tallies.byParty.first)
    #expect(republican.party == "Republican")
    #expect(republican.counts.yea?.value == 155)
    #expect(republican.counts.nay?.value == 14)
    #expect(republican.counts.notVoting?.value == 6)
  }

  @Test("Current party rows keep document order and their own published counts")
  func currentPartyRowsKeepDocumentOrderAndTheirOwnPublishedCounts() throws {
    let tallies = try #require(
      try decode(.house2026, "https://clerk.house.gov/evs/2026/roll314.xml").tallies)
    #expect(tallies.byCandidate.isEmpty)
    #expect(tallies.byParty.map(\.party) == ["Republican", "Democratic", "Independent"])
    #expect(tallies.byParty.map { $0.counts.yea?.value } == [191, 209, 1])
    #expect(tallies.byParty.map { $0.counts.nay?.value } == [14, 0, 0])
    #expect(tallies.byParty.map { $0.counts.present?.value } == [0, 0, 0])
    #expect(tallies.byParty.map { $0.counts.notVoting?.value } == [13, 5, 0])
    let row = try #require(tallies.byVote.first)
    #expect(tallies.byVote.count == 1)
    #expect(row.yea?.value == 401)
    #expect(row.nay?.value == 14)
    #expect(row.notVoting?.value == 18)
    // A published zero is a value; an unpublished field is nil.
    #expect(row.present?.rawValue == "0")
    #expect(row.present?.value == 0)
    #expect(row.aye == nil)
    #expect(row.rawNode.child("total-stub")?.text == "Totals")
  }

  @Test("Speaker candidate rows keep literal labels and assume no party group")
  func speakerCandidateRowsKeepLiteralLabelsAndAssumeNoPartyGroup() throws {
    let tallies = try #require(
      try decode(.house2025_speaker, "https://clerk.house.gov/evs/2025/roll002.xml").tallies)
    #expect(tallies.byParty.isEmpty)
    #expect(tallies.byVote.isEmpty)
    #expect(
      tallies.byCandidate.map(\.candidate)
        == ["Johnson (LA)", "Jeffries", "Emmer", "Present", "Not Voting"])
    #expect(tallies.byCandidate.map { $0.count?.rawValue } == ["218", "215", "1", "0", "0"])
    #expect(tallies.byCandidate.map { $0.count?.value } == [218, 215, 1, 0, 0])
    #expect(tallies.byCandidate.allSatisfy { $0.count?.name == "candidate-total" })
  }

  @Test(
    "Reading tallies leaves stored values and encoding unchanged",
    arguments: [Fixture.house1990, .house1990_vote, .house2025_speaker, .house2026])
  func readingTalliesLeavesStoredValuesAndEncodingUnchanged(fixture: Fixture) throws {
    let rollCall = try decode(fixture, "https://clerk.house.gov/evs/")
    let encoder = JSONEncoder()
    encoder.outputFormatting = .sortedKeys
    let before = try encoder.encode(rollCall)
    _ = rollCall.tallies
    #expect(try encoder.encode(rollCall) == before)
    #expect(try JSONDecoder().decode(HouseRollCall.self, from: before) == rollCall)
  }

  @Test("The encoded roll call keeps exactly its stored keys")
  func theEncodedRollCallKeepsExactlyItsStoredKeys() throws {
    let rollCall = try decode(.house2026, "https://clerk.house.gov/evs/2026/roll314.xml")
    let object = try #require(
      try JSONSerialization.jsonObject(with: JSONEncoder().encode(rollCall)) as? [String: Any])
    #expect(
      Set(object.keys) == [
        "actionDate", "actionTime", "congress", "legislation", "number", "question", "rawNode",
        "recordedVoters", "result", "session", "totals", "voteType",
      ])
    #expect(rollCall.legislation == "S 2403")
    #expect(rollCall.recordedVoters.count == 433)
    #expect(
      rollCall.totals == [
        "not-voting-total": "18", "nay-total": "14", "present-total": "0", "total-stub": "Totals",
        "yea-total": "401",
      ])
    let speaker = try decode(.house2025_speaker, "https://clerk.house.gov/evs/2025/roll002.xml")
    #expect(speaker.legislation == nil)
    #expect(speaker.recordedVoters.count == 434)
    #expect(speaker.totals.isEmpty)
  }

  @Test("A document without vote totals has no tallies")
  func aDocumentWithoutVoteTotalsHasNoTallies() throws {
    // Test-authored mutation of the 2026 roll 314 fixture: the vote-totals element is removed.
    let rollCall = try house2026(replacingVoteTotalsWith: "")
    #expect(rollCall.tallies == nil)
    #expect(rollCall.totals.isEmpty)
  }

  @Test("Empty vote totals and empty rows stay present and empty")
  func emptyVoteTotalsAndEmptyRowsStayPresentAndEmpty() throws {
    // Test-authored mutation of the 2026 roll 314 fixture: an empty vote-totals element.
    let empty = try #require(try house2026(replacingVoteTotalsWith: "<vote-totals/>").tallies)
    #expect(empty.byCandidate.isEmpty)
    #expect(empty.byParty.isEmpty)
    #expect(empty.byVote.isEmpty)
    // Test-authored mutation: one empty aggregate row and one empty party row.
    let rows = try #require(
      try house2026(
        replacingVoteTotalsWith: "<vote-totals><totals-by-party/><totals-by-vote/></vote-totals>"
      ).tallies)
    #expect(rows.byVote.count == 1)
    #expect(rows.byVote.first?.counts.isEmpty == true)
    #expect(rows.byVote.first?.yea == nil)
    #expect(rows.byParty.count == 1)
    #expect(rows.byParty.first?.party == nil)
    #expect(rows.byParty.first?.counts.counts.isEmpty == true)
  }

  @Test("A repeated count field yields no scalar but keeps every entry")
  func aRepeatedCountFieldYieldsNoScalarButKeepsEveryEntry() throws {
    // Test-authored mutation of the 2026 roll 314 fixture: yea-total appears twice in one row.
    let rollCall = try house2026(
      replacingVoteTotalsWith: """
        <vote-totals><totals-by-vote><total-stub>Totals</total-stub><yea-total>401</yea-total>\
        <yea-total>400</yea-total><nay-total>14</nay-total></totals-by-vote></vote-totals>
        """)
    let row = try #require(rollCall.tallies?.byVote.first)
    #expect(row.yea == nil)
    #expect(row.counts.map(\.name) == ["yea-total", "yea-total", "nay-total"])
    #expect(row.counts.map(\.rawValue) == ["401", "400", "14"])
    #expect(row.nay?.value == 14)
  }

  @Test(
    "Counts that are not complete nonnegative decimals keep their raw text only",
    arguments: [
      ("0", 0), ("007", 7), ("9223372036854775807", Int.max), ("", nil), ("-1", nil),
      ("9223372036854775808", nil), (" 5", nil), ("5 ", nil), ("+5", nil), ("1.0", nil),
      ("5a", nil),
    ] as [(String, Int?)])
  func countsThatAreNotCompleteNonnegativeDecimalsKeepTheirRawTextOnly(
    raw: String, expected: Int?
  ) throws {
    // Test-authored mutation of the 2026 roll 314 fixture: yea-total carries the argument text.
    let rollCall = try house2026(
      replacingVoteTotalsWith:
        "<vote-totals><totals-by-vote><yea-total>\(raw)</yea-total></totals-by-vote></vote-totals>")
    let yea = try #require(rollCall.tallies?.byVote.first?.yea)
    #expect(yea.rawValue == raw)
    #expect(yea.value == expected)
  }

  @Test("Unknown fields and rows stay representable")
  func unknownFieldsAndRowsStayRepresentable() throws {
    // Test-authored mutation of the 2026 roll 314 fixture: an unknown total field, an unknown
    // non-total element, an aye-total and no-total pair, and an unknown row kind.
    let rollCall = try house2026(
      replacingVoteTotalsWith: """
        <vote-totals><totals-by-vote><total-stub>Totals</total-stub><aye-total>3</aye-total>\
        <no-total>2</no-total><paired-total>4</paired-total><note>x</note></totals-by-vote>\
        <totals-by-region><region>West</region></totals-by-region></vote-totals>
        """)
    let tallies = try #require(rollCall.tallies)
    let row = try #require(tallies.byVote.first)
    #expect(row.counts.map(\.name) == ["aye-total", "no-total", "paired-total"])
    #expect(row.aye?.value == 3)
    #expect(row.no?.value == 2)
    #expect(row.yea == nil)
    #expect(row.nay == nil)
    #expect(row.rawNode.child("note")?.text == "x")
    #expect(tallies.byParty.isEmpty)
    #expect(tallies.byCandidate.isEmpty)
    #expect(tallies.rawNode.child("totals-by-region")?.child("region")?.text == "West")
  }

  @Test("Repeated rows are kept in document order")
  func repeatedRowsAreKeptInDocumentOrder() throws {
    // Test-authored mutation of the 2026 roll 314 fixture: two aggregate rows.
    let rollCall = try house2026(
      replacingVoteTotalsWith: """
        <vote-totals><totals-by-vote><yea-total>1</yea-total></totals-by-vote>\
        <totals-by-vote><yea-total>2</yea-total></totals-by-vote></vote-totals>
        """)
    #expect(rollCall.tallies?.byVote.map { $0.yea?.value } == [1, 2])
  }

  @Test("A repeated or missing party or candidate label yields no label")
  func aRepeatedOrMissingPartyOrCandidateLabelYieldsNoLabel() throws {
    // Test-authored mutation of the 2026 roll 314 fixture: a party row with two labels, a
    // candidate row with no label, and a candidate row with two counts.
    let rollCall = try house2026(
      replacingVoteTotalsWith: """
        <vote-totals><totals-by-party><party>A</party><party>B</party><yea-total>1</yea-total>\
        </totals-by-party><totals-by-candidate><candidate-total>5</candidate-total>\
        </totals-by-candidate><totals-by-candidate><candidate>C</candidate>\
        <candidate-total>1</candidate-total><candidate-total>2</candidate-total>\
        </totals-by-candidate></vote-totals>
        """)
    let tallies = try #require(rollCall.tallies)
    #expect(tallies.byParty.first?.party == nil)
    #expect(tallies.byParty.first?.counts.yea?.value == 1)
    #expect(tallies.byCandidate.map(\.candidate) == [nil, "C"])
    #expect(tallies.byCandidate.map { $0.count?.value } == [5, nil])
  }

  @Test("A repeated vote totals element uses the first, matching totals")
  func aRepeatedVoteTotalsElementUsesTheFirstMatchingTotals() throws {
    // Test-authored mutation of the 2026 roll 314 fixture: vote-totals appears twice.
    let rollCall = try house2026(
      replacingVoteTotalsWith: """
        <vote-totals><totals-by-vote><yea-total>401</yea-total></totals-by-vote></vote-totals>\
        <vote-totals><totals-by-vote><yea-total>999</yea-total></totals-by-vote></vote-totals>
        """)
    #expect(rollCall.tallies?.byVote.map { $0.yea?.value } == [401])
    #expect(rollCall.totals["yea-total"] == "401")
  }

  @Test("A current Senate bill label is recognized with the document's Congress")
  func aCurrentSenateBillLabelIsRecognizedWithTheDocumentsCongress() throws {
    let rollCall = try decode(.house2026, "https://clerk.house.gov/evs/2026/roll314.xml")
    let reference = try #require(rollCall.legislationReference)
    #expect(reference.rawValue == "S 2403")
    #expect(reference.rawValue == rollCall.legislation)
    let measure = try #require(reference.measure)
    #expect(measure.congress == 119)
    #expect(measure.measureType == .senateBill)
    #expect(measure.measureType.rawValue == "S")
    #expect(measure.number == "2403")
  }

  @Test("A historical House bill label is recognized with its own Congress")
  func aHistoricalHouseBillLabelIsRecognizedWithItsOwnCongress() throws {
    let rollCall = try decode(.house1990_vote, "https://clerk.house.gov/evs/1990/roll010.xml")
    let reference = try #require(rollCall.legislationReference)
    #expect(reference.rawValue == "H R 2190")
    let measure = try #require(reference.measure)
    #expect(measure.congress == 101)
    #expect(measure.measureType == .houseBill)
    #expect(measure.number == "2190")
  }

  @Test("A quorum call label is kept with no recognized measure")
  func aQuorumCallLabelIsKeptWithNoRecognizedMeasure() throws {
    let rollCall = try decode(.house1990, "https://clerk.house.gov/evs/1990/roll001.xml")
    let reference = try #require(rollCall.legislationReference)
    #expect(reference.rawValue == "QUORUM 1")
    #expect(reference.measure == nil)
  }

  @Test("An election of the Speaker has no legislation reference")
  func anElectionOfTheSpeakerHasNoLegislationReference() throws {
    let rollCall = try decode(.house2025_speaker, "https://clerk.house.gov/evs/2025/roll002.xml")
    #expect(rollCall.legislationReference == nil)
    #expect(rollCall.legislation == nil)
  }

  @Test(
    "Each anchored label form is recognized as its measure type",
    arguments: [
      ("H R 1", HouseMeasureType.houseBill, "1"),
      ("H RES 5", .houseResolution, "5"),
      ("H J RES 7", .houseJointResolution, "7"),
      ("H CON RES 9", .houseConcurrentResolution, "9"),
      ("S J RES 2", .senateJointResolution, "2"),
      ("S RES 3", .senateResolution, "3"),
      ("S CON RES 4", .senateConcurrentResolution, "4"),
      ("S 10", .senateBill, "10"),
      ("H R 9223372036854775808", .houseBill, "9223372036854775808"),
    ])
  func eachAnchoredLabelFormIsRecognizedAsItsMeasureType(
    label: String, measureType: HouseMeasureType, number: String
  ) throws {
    // Test-authored mutation of the 2026 roll 314 fixture: legis-num text is replaced.
    let reference = try #require(
      try house2026(replacingLegislationWith: "<legis-num>\(label)</legis-num>")
        .legislationReference)
    #expect(reference.rawValue == label)
    let measure = try #require(reference.measure)
    #expect(measure.congress == 119)
    #expect(measure.measureType == measureType)
    #expect(measure.number == number)
  }

  @Test(
    "An unanchored label keeps its text and yields no measure",
    arguments: [
      "", " ", "S", "H R", "H R ", " H R 1", "H R 1 ", "H  R 1", "H R  1", "h r 1", "H.R. 1",
      "S.J.RES. 42", "H R 1 2", "H R 1a", "H R 01", "H R 0", "H R -1", "H R +1", "H R 1.0",
      "H R １", "H B 1", "S CON 4", "QUORUM 1", "H R 1 and H R 2", "H R\u{00A0}1", "H R 1\n",
    ])
  func anUnanchoredLabelKeepsItsTextAndYieldsNoMeasure(label: String) throws {
    // Test-authored mutation of the 2026 roll 314 fixture: legis-num text is replaced.
    let reference = try #require(
      try house2026(replacingLegislationWith: "<legis-num>\(label)</legis-num>")
        .legislationReference)
    #expect(reference.rawValue == label)
    #expect(reference.measure == nil)
  }

  @Test("A removed label yields no reference and a repeated label uses the first")
  func aRemovedLabelYieldsNoReferenceAndARepeatedLabelUsesTheFirst() throws {
    // Test-authored mutations of the 2026 roll 314 fixture: legis-num removed, then doubled.
    let removed = try house2026(replacingLegislationWith: "")
    #expect(removed.legislationReference == nil)
    #expect(removed.legislation == nil)
    let repeated = try house2026(
      replacingLegislationWith: "<legis-num>H R 1</legis-num><legis-num>S 2</legis-num>")
    #expect(repeated.legislationReference?.rawValue == "H R 1")
    #expect(repeated.legislationReference?.rawValue == repeated.legislation)
    #expect(repeated.legislationReference?.measure?.measureType == .houseBill)
  }

  @Test("A consumer can name a measure type the projection never produces")
  func aConsumerCanNameAMeasureTypeTheProjectionNeverProduces() throws {
    let custom = HouseMeasureType(rawValue: "H B")
    #expect(custom.rawValue == "H B")
    #expect(custom != .houseBill)
    let reference = try #require(
      try house2026(replacingLegislationWith: "<legis-num>H B 1</legis-num>")
        .legislationReference)
    #expect(reference.measure == nil)
  }

  @Test(
    "Reading the legislation reference leaves stored values and encoding unchanged",
    arguments: [Fixture.house1990, .house1990_vote, .house2025_speaker, .house2026])
  func readingTheLegislationReferenceLeavesStoredValuesAndEncodingUnchanged(fixture: Fixture)
    throws
  {
    let rollCall = try decode(fixture, "https://clerk.house.gov/evs/")
    let encoder = JSONEncoder()
    encoder.outputFormatting = .sortedKeys
    let before = try encoder.encode(rollCall)
    _ = rollCall.legislationReference
    #expect(try encoder.encode(rollCall) == before)
    #expect(try JSONDecoder().decode(HouseRollCall.self, from: before) == rollCall)
    let object = try #require(try JSONSerialization.jsonObject(with: before) as? [String: Any])
    #expect(object["legislationReference"] == nil)
    #expect(object["measure"] == nil)
  }

  private func decode(_ fixture: Fixture, _ source: String) throws -> HouseRollCall {
    try HouseRollCall.decode(fixture.data(), sourceURL: #require(URL(string: source)))
  }

  private func house2026(replacingLegislationWith replacement: String) throws -> HouseRollCall {
    var text = try #require(String(data: Fixture.house2026.data(), encoding: .utf8))
    let element = try #require(text.range(of: "<legis-num>S 2403</legis-num>"))
    text.replaceSubrange(element, with: replacement)
    return try HouseRollCall.decode(
      Data(text.utf8),
      sourceURL: #require(URL(string: "https://clerk.house.gov/evs/2026/roll314.xml")))
  }

  private func house2026(replacingVoteTotalsWith replacement: String) throws -> HouseRollCall {
    var text = try #require(String(data: Fixture.house2026.data(), encoding: .utf8))
    let start = try #require(text.range(of: "<vote-totals>"))
    let end = try #require(text.range(of: "</vote-totals>"))
    text.replaceSubrange(start.lowerBound..<end.upperBound, with: replacement)
    return try HouseRollCall.decode(
      Data(text.utf8),
      sourceURL: #require(URL(string: "https://clerk.house.gov/evs/2026/roll314.xml")))
  }
}
