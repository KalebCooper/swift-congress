#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import SwiftCongressBioguideModels
import SwiftCongressBioguideTestSupport
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct BioguideServiceModelsTests {
  @Test("A Congress number below one is rejected", arguments: [0, -1, Int.min])
  func aCongressNumberBelowOneIsRejected(number: Int) {
    #expect(throws: BioguideInputError.invalidCongress) {
      try BioguideCongressIdentifier(congressType: .usCongress, number: number)
    }
  }

  @Test("The same number in two bodies names two Congresses")
  func theSameNumberInTwoBodiesNamesTwoCongresses() throws {
    let continental = try BioguideCongressIdentifier(congressType: .continentalCongress, number: 2)
    let federal = try BioguideCongressIdentifier(congressType: .usCongress, number: 2)
    let repeated = try BioguideCongressIdentifier(congressType: .continentalCongress, number: 2)
    #expect(continental != federal)
    #expect(continental == repeated)
    #expect(
      try BioguideCongressIdentifier(congressType: .usCongress, number: 1_000).number == 1_000)
  }

  @Test("Vocabulary constants keep the exact source spellings")
  func vocabularyConstantsKeepTheExactSourceSpellings() {
    #expect(BioguideCongressType.confederationCongress.rawValue == "ConfederationCongress")
    #expect(BioguideCongressType.continentalCongress.rawValue == "ContinentalCongress")
    #expect(BioguideCongressType.usCongress.rawValue == "USCongress")
    #expect(BioguideJobName.delegate.rawValue == "Delegate")
    #expect(BioguideJobName.representative.rawValue == "Representative")
    #expect(BioguideJobName.residentCommissioner.rawValue == "Resident Commissioner")
    #expect(BioguideJobName.senator.rawValue == "Senator")
    #expect(BioguideJobName(rawValue: "Speaker Of The House").rawValue == "Speaker Of The House")
    #expect(BioguideJobName(rawValue: "delegate") != .delegate)
  }

  @Test("A Continental Delegate query returns only the Continental position")
  func aContinentalDelegateQueryReturnsOnlyTheContinentalPosition() throws {
    let profile = try decodedProfile(.historical)
    let continental = try BioguideCongressIdentifier(congressType: .continentalCongress, number: 2)
    let query = BioguideServiceQuery(congress: continental, job: .delegate, regionCode: "PA")
    let matches = profile.positions(matching: query)
    #expect(matches == [profile.jobPositions[0]])
    #expect(matches.first?.startDate == nil)
    #expect(matches.first?.congressAffiliation?.congress?.name == "The 2nd Continental Congress")
  }

  @Test("A U.S. Congress query does not match predecessor service")
  func aUSCongressQueryDoesNotMatchPredecessorService() throws {
    let profile = try decodedProfile(.historical)
    let federal = try BioguideCongressIdentifier(congressType: .usCongress, number: 2)
    let query = BioguideServiceQuery(congress: federal)
    let matches = profile.positions(matching: query)
    #expect(matches == [profile.jobPositions[2]])
    #expect(matches.first?.jobDetails?.name == .senator)
    #expect(matches.first?.congressAffiliation?.congress?.name == "The 2nd United States Congress")
  }

  @Test("A Confederation Congress query does not match Continental service with the same number")
  func aConfederationCongressQueryDoesNotMatchContinentalServiceWithTheSameNumber() throws {
    let profile = try decodedProfile(.confederation)
    let confederation = try BioguideCongressIdentifier(
      congressType: .confederationCongress, number: 1)
    let continental = try BioguideCongressIdentifier(congressType: .continentalCongress, number: 1)
    let federal = try BioguideCongressIdentifier(congressType: .usCongress, number: 1)
    let matches = profile.positions(
      matching: BioguideServiceQuery(congress: confederation, job: .delegate, regionCode: "NY"))
    #expect(matches == [profile.jobPositions[1]])
    #expect(matches.first?.congressAffiliation?.congress?.name == "The Confederation Congress")
    #expect(
      profile.positions(matching: BioguideServiceQuery(congress: continental))
        == [profile.jobPositions[0]])
    #expect(profile.positions(matching: BioguideServiceQuery(congress: federal)).isEmpty)
  }

  @Test("Modern job and region views read the retained source objects")
  func modernJobAndRegionViewsReadTheRetainedSourceObjects() throws {
    let profile = try decodedProfile(.current)
    let congress = try BioguideCongressIdentifier(congressType: .usCongress, number: 117)
    let matches = profile.positions(
      matching: BioguideServiceQuery(congress: congress, job: .representative, regionCode: "TX"))
    #expect(matches == [profile.jobPositions[2]])
    let job = try #require(matches.first?.jobDetails)
    #expect(job.name == .representative)
    #expect(job.jobType == "CongressMemberJob")
    #expect(job.rawFields == matches.first?.job?.object)
    let region = try #require(matches.first?.congressAffiliation?.representedRegion)
    #expect(region.regionCode == "TX")
    #expect(region.regionType == "DistrictRegion")
    #expect(region.rawFields == matches.first?.congressAffiliation?.represents?.object)
    #expect(
      profile.positions(matching: BioguideServiceQuery(congress: congress, job: .senator))
        .isEmpty)
  }

  @Test("Predicates combine on one position, never across positions")
  func predicatesCombineOnOnePositionNeverAcrossPositions() throws {
    let profile = try decodedProfile(.historical)
    let continental = try BioguideCongressIdentifier(congressType: .continentalCongress, number: 2)
    let firstFederal = try BioguideCongressIdentifier(congressType: .usCongress, number: 1)
    #expect(
      profile.positions(matching: BioguideServiceQuery(congress: continental, job: .senator))
        .isEmpty)
    #expect(
      profile.positions(matching: BioguideServiceQuery(congress: firstFederal, job: .delegate))
        .isEmpty)
    #expect(
      profile.positions(matching: BioguideServiceQuery(job: .senator, regionCode: "PA"))
        == Array(profile.jobPositions[1...3]))
  }

  @Test("An empty query matches every position and a profile without service matches none")
  func anEmptyQueryMatchesEveryPositionAndAProfileWithoutServiceMatchesNone() throws {
    let current = try decodedProfile(.current)
    #expect(current.positions(matching: BioguideServiceQuery()) == current.jobPositions)
    let noService = try decodedProfile(.noService)
    #expect(noService.positions(matching: BioguideServiceQuery()).isEmpty)
    #expect(noService.positions(matching: BioguideServiceQuery(job: .representative)).isEmpty)
  }

  @Test("Region codes and job names match only their exact case")
  func regionCodesAndJobNamesMatchOnlyTheirExactCase() throws {
    let profile = try decodedProfile(.current)
    #expect(profile.positions(matching: BioguideServiceQuery(regionCode: "tx")).isEmpty)
    #expect(
      profile.positions(
        matching: BioguideServiceQuery(job: BioguideJobName(rawValue: "representative"))
      ).isEmpty)
    #expect(profile.positions(matching: BioguideServiceQuery(regionCode: "TX")).count == 5)
  }

  // Test-authored mutation of the M000985 fixture: an unknown body type and job name.
  @Test("Unknown body types and job names stay raw and match only exactly")
  func unknownBodyTypesAndJobNamesStayRawAndMatchOnlyExactly() throws {
    let profile = try mutatedProfile(.historical, position: 0) { position in
      var affiliation = position["congressAffiliation"]?.object ?? [:]
      var congress = affiliation["congress"]?.object ?? [:]
      congress["congressType"] = .string("ProvincialCongress")
      affiliation["congress"] = .object(congress)
      position["congressAffiliation"] = .object(affiliation)
      position["job"] = .object([
        "jobType": .string("CongressMemberJob"), "name": .string("Deputy"),
        "tenure": .string("unrecognized"),
      ])
    }
    let unknownBody = try BioguideCongressIdentifier(
      congressType: BioguideCongressType(rawValue: "ProvincialCongress"), number: 2)
    let matches = profile.positions(
      matching: BioguideServiceQuery(
        congress: unknownBody, job: BioguideJobName(rawValue: "Deputy")))
    #expect(matches == [profile.jobPositions[0]])
    #expect(matches.first?.jobDetails?.name?.rawValue == "Deputy")
    #expect(matches.first?.jobDetails?.rawFields["tenure"] == .string("unrecognized"))
    let continental = try BioguideCongressIdentifier(congressType: .continentalCongress, number: 2)
    #expect(profile.positions(matching: BioguideServiceQuery(congress: continental)).isEmpty)
    #expect(profile.positions(matching: BioguideServiceQuery(job: .delegate)).isEmpty)
  }

  // Test-authored mutation of the A000375 fixture: the 117th Congress affiliation loses represents.
  @Test("A missing represents yields no region and fails only a region predicate")
  func aMissingRepresentsYieldsNoRegionAndFailsOnlyARegionPredicate() throws {
    let profile = try mutatedProfile(.current, position: 2) { position in
      var affiliation = position["congressAffiliation"]?.object ?? [:]
      affiliation["represents"] = nil
      position["congressAffiliation"] = .object(affiliation)
    }
    let position = profile.jobPositions[2]
    #expect(position.congressAffiliation?.represents == nil)
    #expect(position.congressAffiliation?.representedRegion == nil)
    let congress = try BioguideCongressIdentifier(congressType: .usCongress, number: 117)
    #expect(
      profile.positions(matching: BioguideServiceQuery(congress: congress, regionCode: "TX"))
        .isEmpty)
    #expect(profile.positions(matching: BioguideServiceQuery(congress: congress)) == [position])
    #expect(profile.positions(matching: BioguideServiceQuery(regionCode: "TX")).count == 4)
  }

  // Test-authored mutation of the A000375 fixture: the 115th Congress position loses its
  // congressAffiliation, then separately only the affiliation's congress object.
  @Test("A missing Congress affiliation or Congress fails only a Congress predicate")
  func aMissingCongressAffiliationOrCongressFailsOnlyACongressPredicate() throws {
    let withoutAffiliation = try mutatedProfile(.current, position: 0) { position in
      position["congressAffiliation"] = nil
    }
    let withoutCongress = try mutatedProfile(.current, position: 0) { position in
      var affiliation = position["congressAffiliation"]?.object ?? [:]
      affiliation["congress"] = nil
      position["congressAffiliation"] = .object(affiliation)
    }
    #expect(withoutAffiliation.jobPositions[0].congressAffiliation == nil)
    #expect(withoutCongress.jobPositions[0].congressAffiliation?.congress == nil)
    let congress = try BioguideCongressIdentifier(congressType: .usCongress, number: 115)
    for profile in [withoutAffiliation, withoutCongress] {
      #expect(profile.positions(matching: BioguideServiceQuery(congress: congress)).isEmpty)
      #expect(profile.positions(matching: BioguideServiceQuery()).count == 5)
    }
    #expect(
      withoutCongress.positions(matching: BioguideServiceQuery(regionCode: "TX"))
        .contains(withoutCongress.jobPositions[0]))
  }

  // Test-authored mutation of the A000375 fixture: non-object job and represents values.
  @Test("Non-object job and represents values produce no views and stay raw")
  func nonObjectJobAndRepresentsValuesProduceNoViewsAndStayRaw() throws {
    let profile = try mutatedProfile(.current, position: 0) { position in
      var affiliation = position["congressAffiliation"]?.object ?? [:]
      affiliation["represents"] = .string("TX")
      position["congressAffiliation"] = .object(affiliation)
      position["job"] = .null
    }
    let position = profile.jobPositions[0]
    #expect(position.jobDetails == nil)
    #expect(position.rawFields["job"] == .null)
    #expect(position.congressAffiliation?.representedRegion == nil)
    #expect(position.congressAffiliation?.represents == .string("TX"))
    #expect(
      !profile.positions(matching: BioguideServiceQuery(job: .representative)).contains(position))
  }

  // Test-authored mutation of the M000985 fixture: a year-only, circa start date.
  @Test("Partial and circa dates are left unchanged by matching")
  func partialAndCircaDatesAreLeftUnchangedByMatching() throws {
    let profile = try mutatedProfile(.historical, position: 1) { position in
      position["startCirca"] = .boolean(true)
      position["startDate"] = .string("1789")
    }
    let congress = try BioguideCongressIdentifier(congressType: .usCongress, number: 1)
    let matches = profile.positions(matching: BioguideServiceQuery(congress: congress))
    #expect(matches == [profile.jobPositions[1]])
    #expect(matches.first?.startDate == "1789")
    #expect(matches.first?.startCirca == true)
    #expect(matches.first?.endDate == nil)
  }

  // Test-authored mutation of the A000375 fixture: a repeated 117th Congress position.
  @Test("Repeated positions are all returned in source order")
  func repeatedPositionsAreAllReturnedInSourceOrder() throws {
    let source = try JSONDecoder().decode(JSONValue.self, from: Fixture.current.data())
    var root = try #require(source.object)
    var positions = try #require(root["jobPositions"]?.array)
    positions.append(positions[2])
    root["jobPositions"] = .array(positions)
    let profile = try JSONDecoder().decode(
      BioguideProfile.self, from: JSONEncoder().encode(JSONValue.object(root)))
    let congress = try BioguideCongressIdentifier(congressType: .usCongress, number: 117)
    let matches = profile.positions(matching: BioguideServiceQuery(congress: congress))
    #expect(matches == [profile.jobPositions[2], profile.jobPositions[5]])
    #expect(matches[0] == matches[1])
  }

  @Test(
    "Reading service views leaves every profile's encoding unchanged",
    arguments: [Fixture.confederation, .current, .historical, .noService, .restricted])
  func readingServiceViewsLeavesEveryProfilesEncodingUnchanged(fixture: Fixture) throws {
    let bytes = try fixture.data()
    let profile = try JSONDecoder().decode(BioguideProfile.self, from: bytes)
    for position in profile.positions(matching: BioguideServiceQuery()) {
      _ = position.jobDetails
      _ = position.congressAffiliation?.representedRegion
    }
    #expect(
      try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(profile))
        == JSONDecoder().decode(JSONValue.self, from: bytes))
  }

  private func decodedProfile(_ fixture: Fixture) throws -> BioguideProfile {
    try JSONDecoder().decode(BioguideProfile.self, from: fixture.data())
  }

  /// Decodes a fixture after a test-authored change to one of its source positions.
  private func mutatedProfile(
    _ fixture: Fixture, position index: Int, _ change: (inout [String: JSONValue]) -> Void
  ) throws -> BioguideProfile {
    let source = try JSONDecoder().decode(JSONValue.self, from: fixture.data())
    var root = try #require(source.object)
    var positions = try #require(root["jobPositions"]?.array)
    var position = try #require(positions[index].object)
    change(&position)
    positions[index] = .object(position)
    root["jobPositions"] = .array(positions)
    return try JSONDecoder().decode(
      BioguideProfile.self, from: JSONEncoder().encode(JSONValue.object(root)))
  }
}
