#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import SwiftCongressBioguideModels
import SwiftCongressBioguideTestSupport
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct BioguideModelsTests {
  @Test(
    "All profile fields survive a Codable round trip",
    arguments: [Fixture.current, .historical, .noService, .restricted])
  func allProfileFieldsSurviveACodableRoundTrip(fixture: Fixture) throws {
    let bytes = try fixture.data()
    let profile = try JSONDecoder().decode(BioguideProfile.self, from: bytes)
    #expect(
      try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(profile))
        == JSONDecoder().decode(JSONValue.self, from: bytes))
  }

  @Test("Predecessor bodies and partial dates remain distinct")
  func predecessorBodiesAndPartialDatesRemainDistinct() throws {
    let profile = try JSONDecoder().decode(BioguideProfile.self, from: Fixture.historical.data())
    #expect(profile.usCongressBioId == "M000985")
    #expect(profile.deathDate == "1806")
    #expect(profile.jobPositions.first?.startDate == nil)
    #expect(
      profile.jobPositions.first?.congressAffiliation?.congress?.congressType
        == "ContinentalCongress")
    #expect(profile.jobPositions.first?.congressAffiliation?.congress?.congressNumber == 2)
    #expect(
      profile.jobPositions.dropFirst().first?.congressAffiliation?.congress?.congressType
        == "USCongress")
  }

  @Test("Profiles without service and restricted assets are preserved")
  func profilesWithoutServiceAndRestrictedAssetsArePreserved() throws {
    let empty = try JSONDecoder().decode(BioguideProfile.self, from: Fixture.noService.data())
    #expect(empty.jobPositions.isEmpty)
    let profile = try JSONDecoder().decode(BioguideProfile.self, from: Fixture.restricted.data())
    #expect(
      profile.asset?.contains(where: {
        $0.object?["usageRight"]?.array?.contains(.string("Restricted")) == true
      }) == true)
  }
}
