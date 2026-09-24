import Foundation
import SwiftCongressBioguide
import SwiftCongressBioguideModels
import SwiftCongressBioguideTestSupport
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct BioguideImporterTests {
  @Test("Cancelled import stops before opening the directory")
  func cancelledImportStopsBeforeOpeningTheDirectory() async throws {
    let importer = try BioguideImporter(manifest: manifest())
    let (stream, continuation) = AsyncStream<Void>.makeStream()
    let task = Task { () async throws -> Void in
      for await _ in stream {}
      var iterator = importer.records(in: URL(fileURLWithPath: "/not-present")).makeAsyncIterator()
      await #expect(throws: BioguideError.cancelled) { try await iterator.next() }
      #expect(try await iterator.next() == nil)
    }
    task.cancel()
    continuation.finish()
    try await task.value
  }

  @Test("Duplicate paths and identifiers fail manifest validation")
  func duplicatePathsAndIdentifiersFailManifestValidation() throws {
    let source = try manifest()
    let entry = try #require(source.entries.first)
    let duplicated = BioguideManifest(
      archiveSHA256: source.archiveSHA256, entries: [entry, entry],
      profileCount: 2, retrievedAt: source.retrievedAt, sourceURL: source.sourceURL)
    #expect(throws: BioguideError.invalidManifest) { try BioguideImporter(manifest: duplicated) }
  }

  @Test("Invalid paths and decompression bounds fail before reading files")
  func invalidPathsAndDecompressionBoundsFailBeforeReadingFiles() throws {
    let source = try manifest()
    let entry = BioguideManifestEntry(
      byteCount: 12, filename: "../profile.json", identifier: "profile",
      sha256: String(repeating: "a", count: 64))
    let traversal = BioguideManifest(
      archiveSHA256: source.archiveSHA256, entries: [entry],
      profileCount: 1, retrievedAt: source.retrievedAt, sourceURL: source.sourceURL)
    #expect(throws: BioguideError.invalidManifest) { try BioguideImporter(manifest: traversal) }
    #expect(throws: BioguideError.invalidManifest) {
      try BioguideImporter(manifest: source, maximumProfileBytes: 1)
    }
    #expect(throws: BioguideError.invalidManifest) {
      try BioguideImporter(manifest: source, maximumProfiles: 1)
    }
    #expect(throws: BioguideError.invalidManifest) {
      try BioguideImporter(manifest: source, maximumTotalBytes: 1)
    }
  }

  @Test("Missing directories fail lazily and terminate the iterator")
  func missingDirectoriesFailLazilyAndTerminateTheIterator() async throws {
    let importer = try BioguideImporter(manifest: manifest())
    let missing = try Fixture.directory().appendingPathComponent("not-present")
    var iterator = importer.records(in: missing).makeAsyncIterator()
    await #expect(throws: BioguideError.invalidDirectory) { try await iterator.next() }
    #expect(try await iterator.next() == nil)
  }

  @Test("Profiles are read independently with exact bytes and stable repeat counts")
  func profilesAreReadIndependentlyWithExactBytesAndStableRepeatCounts() async throws {
    let importer = try BioguideImporter(manifest: manifest())
    let records = importer.records(in: try Fixture.directory().resolvingSymlinksInPath())
    var first = records.makeAsyncIterator()
    var second = records.makeAsyncIterator()
    #expect(try await first.next()?.body == Fixture.current.data())
    #expect(try await second.next()?.profile.usCongressBioId == "A000375")
    for _ in 0..<2 {
      var count = 0
      for try await record in records {
        #expect(record.entry.identifier == record.profile.usCongressBioId)
        count += 1
      }
      #expect(count == importer.manifest.profileCount)
    }
  }

  @Test("Wrong profile digests never yield a record")
  func wrongProfileDigestsNeverYieldARecord() async throws {
    let source = try manifest()
    let entries = source.entries.map {
      BioguideManifestEntry(
        byteCount: $0.byteCount, filename: $0.filename, identifier: $0.identifier,
        sha256: String(repeating: "a", count: 64))
    }
    let changed = BioguideManifest(
      archiveSHA256: source.archiveSHA256, entries: entries,
      profileCount: source.profileCount, retrievedAt: source.retrievedAt,
      sourceURL: source.sourceURL)
    var iterator = try BioguideImporter(manifest: changed).records(
      in: Fixture.directory().resolvingSymlinksInPath()
    ).makeAsyncIterator()
    await #expect(throws: BioguideError.corruptProfile("A000375")) { try await iterator.next() }
    #expect(try await iterator.next() == nil)
  }

  private func manifest() throws -> BioguideManifest {
    try JSONDecoder().decode(
      BioguideManifest.self,
      from: Data(contentsOf: Fixture.directory().appendingPathComponent("manifest.json")))
  }
}
