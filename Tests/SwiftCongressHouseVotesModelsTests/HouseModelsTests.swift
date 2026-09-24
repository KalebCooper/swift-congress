import Foundation
import SwiftCongressHouseVotesModels
import SwiftCongressHouseVotesTestSupport
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct HouseModelsTests {
  @Test func historicalAndCurrentRowsPreserveSourceIdentity() throws {
    let url = try #require(URL(string: "https://clerk.house.gov/evs/1990/roll001.xml"))
    let quorum = try HouseRollCall.decode(Fixture.house1990.data(), sourceURL: url)
    #expect(quorum.recordedVoters.count == 430)
    #expect(quorum.recordedVoters.allSatisfy { $0.nameID == nil })
    #expect(quorum.totals["present-total"] == "376")
    let old = try HouseRollCall.decode(Fixture.house1990_vote.data(), sourceURL: url)
    #expect(old.recordedVoters.count == 431)
    #expect(Set(old.recordedVoters.map(\.position.rawValue)) == ["Aye", "No", "Not Voting"])
    let current = try HouseRollCall.decode(Fixture.house2026.data(), sourceURL: url)
    #expect(current.recordedVoters.count == 433)
    #expect(current.recordedVoters.allSatisfy { $0.nameID != nil })
    #expect(current.totals["yea-total"] == "401")
    #expect(
      try JSONDecoder().decode(HouseRollCall.self, from: JSONEncoder().encode(current)) == current)
  }

  @Test func indexesExposeOnlyPublishedLinks() throws {
    let index = try HouseVoteIndex.decode(
      Fixture.house_index.data(),
      sourceURL: #require(URL(string: "https://clerk.house.gov/evs/2026/index.asp")))
    #expect(index.votes.contains { $0.identifier.number == 314 })
    #expect(index.sections.contains { $0.path == "/evs/2026/ROLL_300.asp" })
    let section = try HouseVoteIndex.decode(
      Fixture.house_section1990.data(),
      sourceURL: #require(URL(string: "https://clerk.house.gov/evs/1990/ROLL_000.asp")))
    #expect(section.votes.contains { $0.identifier.number == 1 })
    #expect(section.votes.allSatisfy { $0.identifier.year == 1990 })
    #expect(Endpoint<HouseRollCall>(path: "/evs/2026/../secret") == nil)
    #expect(Endpoint<HouseRollCall>(path: "/evs/2026/roll001.xml?key=x") == nil)
    #expect(
      Endpoint.rollCall(try HouseVoteIdentifier(number: 1000, year: 2026)).path
        == "/evs/2026/roll1000.xml")
  }

  @Test func inventoriesIgnoreCommentsAndScriptTextAndHandleQuotedAngles() throws {
    let html = """
      <html><title>Roll Call</title><script>let example = '<a href="/cgi-bin/vote.asp?year=2026&rollnumber=99">';</script>
      <!-- <a href="/cgi-bin/vote.asp?year=2026&rollnumber=98"> -->
      <a title="a > b" href="/cgi-bin/vote.asp?year=2026&amp;rollnumber=314">Vote</a></html>
      """
    let url = try #require(URL(string: "https://clerk.house.gov/evs/2026/index.asp"))
    let value = try HouseVoteIndex.decode(Data(html.utf8), sourceURL: url)
    #expect(value.votes.map(\.identifier.number) == [314])
    #expect(throws: HouseDecodingError.invalidDocument) {
      try HouseVoteIndex.decode(Data("<html>Roll Call unavailable</html>".utf8), sourceURL: url)
    }
  }

  @Test func xmlPreservesMixedTextAndRejectsUnboundedOrEntityContent() throws {
    let tree = try HouseXMLCodec.decode(
      Data("<x:r xmlns:x='urn:test' unknown='yes'>before<x:v>é</x:v>after</x:r>".utf8))
    #expect(tree.localName == "r")
    #expect(tree.text == "beforeéafter")
    #expect(tree.attributes["unknown"] == "yes")
    #expect(throws: HouseDecodingError.limitExceeded) {
      try HouseXMLCodec.decode(Data("<r><v/></r>".utf8), maximumDepth: 1)
    }
    #expect(throws: HouseDecodingError.limitExceeded) {
      try HouseXMLCodec.decode(Data("<r/>".utf8), maximumBytes: 1)
    }
    #expect(throws: HouseDecodingError.invalidDocument) {
      try HouseXMLCodec.decode(Data("<r>".utf8))
    }
    #expect(throws: HouseDecodingError.invalidDocument) {
      try HouseXMLCodec.decode(
        Data("<!DOCTYPE r [<!ENTITY leak SYSTEM 'file:///etc/passwd'>]><r>&leak;</r>".utf8))
    }
    let legacy = Data([60, 114, 62, 233, 60, 47, 114, 62])
    var bytes = Data("<?xml version='1.0' encoding='ISO-8859-1'?>".utf8); bytes.append(legacy)
    #expect(try HouseXMLCodec.decode(bytes).text == "é")
  }
}
