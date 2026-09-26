import Foundation
import SwiftCongressBioguide
import SwiftCongressBioguideModels
import SwiftCongressBioguideTestSupport
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct BioguideServiceTests {
  @Test("A cancelled matching scan throws before reading a corrupt profile")
  func aCancelledMatchingScanThrowsBeforeReadingACorruptProfile() async throws {
    let directory = try stage(corrupting: ["H000619"])
    defer { try? FileManager.default.removeItem(at: directory) }
    let records = try BioguideImporter(manifest: manifest()).records(
      in: directory, matching: BioguideServiceQuery(regionCode: "PA"))
    let (stream, continuation) = AsyncStream<Void>.makeStream()
    let task = Task { () async throws -> Void in
      for await _ in stream {}
      var iterator = records.makeAsyncIterator()
      await #expect(throws: BioguideError.cancelled) { try await iterator.next() }
      #expect(try await iterator.next() == nil)
    }
    task.cancel()
    continuation.finish()
    try await task.value
  }

  @Test("A corrupt later profile does not throw until the scan reaches it")
  func aCorruptLaterProfileDoesNotThrowUntilTheScanReachesIt() async throws {
    let directory = try stage(corrupting: ["M000985"])
    defer { try? FileManager.default.removeItem(at: directory) }
    var iterator = try BioguideImporter(manifest: manifest()).records(
      in: directory, matching: BioguideServiceQuery(regionCode: "TX")
    ).makeAsyncIterator()
    #expect(try await iterator.next()?.entry.identifier == "A000375")
    await #expect(throws: BioguideError.corruptProfile("M000985")) { try await iterator.next() }
    #expect(try await iterator.next() == nil)
  }

  @Test("A profile with several matching positions is yielded once")
  func aProfileWithSeveralMatchingPositionsIsYieldedOnce() async throws {
    let directory = try stage()
    defer { try? FileManager.default.removeItem(at: directory) }
    let records = try BioguideImporter(manifest: manifest()).records(
      in: directory, matching: BioguideServiceQuery(job: .senator))
    var identifiers: [String] = []
    for try await record in records { identifiers.append(record.entry.identifier) }
    #expect(identifiers == ["M000985"])
  }

  @Test("A query with no predicates yields every profile that publishes a position")
  func aQueryWithNoPredicatesYieldsEveryProfileThatPublishesAPosition() async throws {
    let directory = try stage()
    defer { try? FileManager.default.removeItem(at: directory) }
    let records = try BioguideImporter(manifest: manifest()).records(
      in: directory, matching: BioguideServiceQuery())
    var identifiers: [String] = []
    for try await record in records { identifiers.append(record.entry.identifier) }
    #expect(identifiers == ["A000375", "B001323", "H000205", "M000985"])
  }

  @Test("Cancellation after a match stops the scan before the next read")
  func cancellationAfterAMatchStopsTheScanBeforeTheNextRead() async throws {
    let directory = try stage(corrupting: ["B001323"])
    defer { try? FileManager.default.removeItem(at: directory) }
    let records = try BioguideImporter(manifest: manifest()).records(
      in: directory, matching: BioguideServiceQuery())
    let (matched, matchedContinuation) = AsyncStream<Void>.makeStream()
    let (resume, resumeContinuation) = AsyncStream<Void>.makeStream()
    let task = Task { () async throws -> Void in
      var iterator = records.makeAsyncIterator()
      #expect(try await iterator.next()?.entry.identifier == "A000375")
      matchedContinuation.finish()
      for await _ in resume {}
      await #expect(throws: BioguideError.cancelled) { try await iterator.next() }
      #expect(try await iterator.next() == nil)
    }
    for await _ in matched {}
    task.cancel()
    resumeContinuation.finish()
    try await task.value
  }

  @Test("Corruption in a nonmatching scanned profile throws and terminates the iterator")
  func corruptionInANonmatchingScannedProfileThrowsAndTerminatesTheIterator() async throws {
    let directory = try stage(corrupting: ["H000619"])
    defer { try? FileManager.default.removeItem(at: directory) }
    var iterator = try BioguideImporter(manifest: manifest()).records(
      in: directory, matching: BioguideServiceQuery(regionCode: "PA")
    ).makeAsyncIterator()
    await #expect(throws: BioguideError.corruptProfile("H000619")) { try await iterator.next() }
    #expect(try await iterator.next() == nil)
  }

  @Test("Creating a matching sequence and iterator opens nothing")
  func creatingAMatchingSequenceAndIteratorOpensNothing() async throws {
    let missing = try Fixture.directory().appendingPathComponent("not-present")
    let records = try BioguideImporter(manifest: manifest()).records(
      in: missing, matching: BioguideServiceQuery())
    var iterator = records.makeAsyncIterator()
    await #expect(throws: BioguideError.invalidDirectory) { try await iterator.next() }
    #expect(try await iterator.next() == nil)
  }

  @Test("Matching iterators traverse independently and fail independently")
  func matchingIteratorsTraverseIndependentlyAndFailIndependently() async throws {
    let directory = try stage(corrupting: ["H000619"])
    defer { try? FileManager.default.removeItem(at: directory) }
    let records = try BioguideImporter(manifest: manifest()).records(
      in: directory, matching: BioguideServiceQuery(job: .representative))
    var first = records.makeAsyncIterator()
    var second = records.makeAsyncIterator()
    #expect(try await first.next()?.entry.identifier == "A000375")
    #expect(try await second.next()?.entry.identifier == "A000375")
    #expect(try await first.next()?.entry.identifier == "B001323")
    await #expect(throws: BioguideError.corruptProfile("H000619")) { try await first.next() }
    #expect(try await first.next() == nil)
    #expect(try await second.next()?.entry.identifier == "B001323")
  }

  @Test("Nonmatching profiles are skipped and the complete original record is yielded")
  func nonmatchingProfilesAreSkippedAndTheCompleteOriginalRecordIsYielded() async throws {
    let directory = try stage()
    defer { try? FileManager.default.removeItem(at: directory) }
    let source = try manifest()
    let congress = try BioguideCongressIdentifier(congressType: .continentalCongress, number: 2)
    var iterator = try BioguideImporter(manifest: source).records(
      in: directory,
      matching: BioguideServiceQuery(congress: congress, job: .delegate, regionCode: "PA")
    ).makeAsyncIterator()
    let record = try #require(try await iterator.next())
    #expect(record.body == (try Fixture.historical.data()))
    #expect(record.entry == source.entries.last)
    #expect(
      record.profile
        == (try JSONDecoder().decode(BioguideProfile.self, from: Fixture.historical.data())))
    #expect(try await iterator.next() == nil)
  }

  private func manifest() throws -> BioguideManifest {
    try JSONDecoder().decode(
      BioguideManifest.self,
      from: Data(contentsOf: Fixture.directory().appendingPathComponent("manifest.json")))
  }

  /// Copies the recorded fixture directory into a new temporary directory, appending one byte to
  /// each named profile so its length no longer matches the manifest.
  private func stage(corrupting identifiers: Set<String> = []) throws -> URL {
    let source = try Fixture.directory()
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent("BioguideServiceTests-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
    for name in try FileManager.default.contentsOfDirectory(atPath: source.path) {
      var data = try Data(contentsOf: source.appendingPathComponent(name))
      if identifiers.contains(String(name.dropLast(".json".count))), name != "manifest.json" {
        data.append(0x20)
      }
      try data.write(to: directory.appendingPathComponent(name))
    }
    return directory.resolvingSymlinksInPath()
  }
}
