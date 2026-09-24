import Foundation
import SwiftCongressSenateVotesModels
import SwiftCongressSenateVotesTestSupport
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct SenateModelsTests {
  @Test func currentCrosswalkDoesNotImplyHistoricalCoverage() throws {
    let url = try #require(
      URL(string: "https://www.senate.gov/legislative/LIS_MEMBER/cvc_member_data.xml"))
    let identities = try SenateMemberIdentities.decode(
      Fixture.senate_identities.data(), sourceURL: url)
    #expect(identities.identities.count == 100)
    #expect(identities.identities.first?.lisMemberID == "S428")
    #expect(identities.identities.first?.bioguideID == "A000382")
    #expect(identities.lastUpdate?.child("date")?.text.contains("2026") == true)
    let historical = try SenateRollCall.decode(Fixture.senate1989.data(), sourceURL: url)
    let lisIDs = Set(identities.identities.map(\.lisMemberID))
    #expect(
      historical.recordedVoters.filter { $0.lisMemberID.map(lisIDs.contains) == true }.count == 2)
    #expect(
      try JSONDecoder().decode(SenateMemberIdentities.self, from: JSONEncoder().encode(identities))
        == identities)
  }

  @Test func historicalNominationAndModernAmendmentRetainDistinctShapes() throws {
    let url = try #require(
      URL(
        string:
          "https://www.senate.gov/legislative/LIS/roll_call_votes/vote1011/vote_101_1_00001.xml"))
    let old = try SenateRollCall.decode(Fixture.senate1989.data(), sourceURL: url)
    #expect(old.recordedVoters.count == 100)
    #expect(old.modifyDate == nil)
    #expect(old.document?.child("document_type")?.text == "PN")
    #expect(old.counts["present"] == "")
    #expect(old.counts["yeas"] == "99")
    let modern = try SenateRollCall.decode(Fixture.senate2026.data(), sourceURL: url)
    #expect(modern.amendment?.child("amendment_to_document_number")?.text == "S. 4668")
    #expect(modern.recordedVoters.count == 100)
    #expect(modern.counts["yeas"] == "70")
    #expect(
      try JSONDecoder().decode(SenateRollCall.self, from: JSONEncoder().encode(modern)) == modern)
  }

  @Test func inventoriesPreserveNestedQuestionsAndExplicitNumbers() throws {
    let url = try #require(
      URL(string: "https://www.senate.gov/legislative/LIS/roll_call_lists/vote_menu_119_2.xml"))
    let value = try SenateVoteIndex.decode(Fixture.senate_index.data(), sourceURL: url)
    #expect(value.votes.first?.sourceNumber == "00241")
    #expect(value.votes.first?.issue == "PN999-1")
    let amendment = try #require(value.votes.first { $0.identifier.number == 240 })
    #expect(amendment.question?.child("measure")?.text == "S.Amdt. 6776")
    #expect(amendment.question?.text.contains("S.Amdt. 6776") == true)
    let old = try SenateVoteIndex.decode(Fixture.senate_index1989.data(), sourceURL: url)
    #expect(old.congress == 101)
    #expect(old.votes.contains { $0.identifier.number == 1 })
    #expect(
      Endpoint.rollCall(amendment.identifier).path
        == "/legislative/LIS/roll_call_votes/vote1192/vote_119_2_00240.xml")
    #expect(Endpoint<SenateRollCall>(path: "/legislative/../other") == nil)
    #expect(throws: SenateInputError.invalidIdentifier) {
      try SenateVoteIdentifier(congress: 119, number: 1, session: 3)
    }
  }

  @Test func xmlLimitsAndEntityRejectionApplyIndependently() throws {
    #expect(throws: SenateDecodingError.limitExceeded) {
      try SenateXMLCodec.decode(Data("<r><v/></r>".utf8), maximumDepth: 1)
    }
    #expect(throws: SenateDecodingError.invalidDocument) {
      try SenateXMLCodec.decode(Data("<r>".utf8))
    }
    #expect(throws: SenateDecodingError.invalidDocument) {
      try SenateXMLCodec.decode(
        Data("<!DOCTYPE r [<!ENTITY leak SYSTEM 'file:///etc/passwd'>]><r>&leak;</r>".utf8))
    }
    let tree = try SenateXMLCodec.decode(
      Data("<x:r xmlns:x='urn:x'>before<x:v>nested</x:v>after</x:r>".utf8))
    #expect(tree.localName == "r")
    #expect(tree.text == "beforenestedafter")
  }
}
