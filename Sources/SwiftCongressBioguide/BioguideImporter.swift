// Bounded file handles and directory metadata require Foundation on portable platforms.
import Foundation
import Crypto
import SwiftCongressBioguideModels

/// Reads an immutable, caller-staged directory from an official supplied export.
/// It performs no network access and never merges profiles or chooses a refresh policy.
///
/// ```swift
/// let importer = try BioguideImporter(manifest: manifest)
/// for try await record in importer.records(in: directory) { store(record.body) }
/// ```
public struct BioguideImporter: Sendable {
  /// The validated inventory and original archive provenance.
  public let manifest: BioguideManifest
  /// The maximum permitted uncompressed profile size.
  public let maximumProfileBytes: Int

  /// Validates a bounded supplied-file inventory without reading profile files.
  /// The caller must keep the staged directory immutable during iteration.
  /// - Throws: `BioguideError.invalidManifest` for invalid bounds, duplicate paths/IDs, or digests.
  public init(
    manifest: BioguideManifest, maximumProfileBytes: Int = 4_194_304,
    maximumProfiles: Int = 30_000, maximumTotalBytes: Int = 536_870_912
  ) throws(BioguideError) {
    guard maximumProfileBytes > 0, maximumProfileBytes < Int.max, maximumProfiles > 0,
      maximumTotalBytes > 0, manifest.profileCount > 0,
      manifest.profileCount == manifest.entries.count, manifest.entries.count <= maximumProfiles,
      Self.isDigest(manifest.archiveSHA256), !manifest.retrievedAt.isEmpty,
      !manifest.sourceURL.isEmpty
    else { throw .invalidManifest }
    var identifiers: Set<String> = []
    var paths: Set<String> = []
    var total = 0
    for entry in manifest.entries {
      guard !entry.identifier.isEmpty,
        entry.identifier.utf8.allSatisfy({
          (48...57).contains($0) || (65...90).contains($0) || (97...122).contains($0) || $0 == 45
            || $0 == 95
        }),
        entry.filename == entry.identifier + ".json", Self.isDigest(entry.sha256),
        entry.byteCount > 0, entry.byteCount <= maximumProfileBytes,
        entry.byteCount <= maximumTotalBytes - total,
        identifiers.insert(entry.identifier).inserted, paths.insert(entry.filename).inserted
      else { throw .invalidManifest }
      total += entry.byteCount
    }
    self.manifest = manifest; self.maximumProfileBytes = maximumProfileBytes
  }

  /// Creates an independent lazy traversal without opening any profile.
  public func records(in directory: URL) -> BioguideRecords {
    BioguideRecords(directory: directory, importer: self)
  }

  /// Creates an independent lazy traversal of the profiles with a position matching a query.
  ///
  /// Creating the sequence opens nothing. Every scanned profile is verified exactly as by
  /// ``records(in:)``, so corruption in a profile that would not have matched still throws.
  ///
  /// ```swift
  /// let query = BioguideServiceQuery(job: .senator, regionCode: "PA")
  /// for try await record in importer.records(in: directory, matching: query) { store(record.body) }
  /// ```
  /// - Parameters:
  ///   - directory: The immutable, caller-staged export directory.
  ///   - query: The predicates at least one position of a yielded profile satisfies together.
  /// - Returns: A sequence yielding each matching profile's complete record once, in manifest order.
  public func records(in directory: URL, matching query: BioguideServiceQuery)
    -> BioguideMatchingRecords
  {
    BioguideMatchingRecords(query: query, records: records(in: directory))
  }

  @concurrent
  static func read(directory: URL, entry: BioguideManifestEntry, maximumBytes: Int)
    async throws(BioguideError) -> BioguideRecord
  {
    guard !Task.isCancelled else { throw .cancelled }
    let file = directory.appendingPathComponent(entry.filename)
    let bytes: Data
    do {
      let values = try file.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey])
      guard values.isRegularFile == true, values.isSymbolicLink == false else {
        throw BioguideError.invalidDirectory
      }
      let handle = try FileHandle(forReadingFrom: file)
      defer { try? handle.close() }
      bytes = try handle.read(upToCount: maximumBytes + 1) ?? Data()
    } catch let error as BioguideError { throw error } catch { throw .invalidDirectory }
    guard !Task.isCancelled else { throw .cancelled }
    guard bytes.count == entry.byteCount,
      SHA256.hash(data: bytes).map({
        String($0, radix: 16).count == 1 ? "0" + String($0, radix: 16) : String($0, radix: 16)
      }).joined() == entry.sha256
    else { throw .corruptProfile(entry.identifier) }
    let profile: BioguideProfile
    do { profile = try JSONDecoder().decode(BioguideProfile.self, from: bytes) } catch {
      throw .decoding(entry.identifier)
    }
    guard profile.usCongressBioId == entry.identifier else {
      throw .mismatchedIdentifier(entry.identifier)
    }
    guard !Task.isCancelled else { throw .cancelled }
    return BioguideRecord(body: bytes, entry: entry, profile: profile)
  }

  @concurrent
  static func validate(directory: URL, manifest: BioguideManifest) async throws(BioguideError) {
    guard directory.isFileURL else { throw .invalidDirectory }
    do {
      let values = try directory.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
      guard values.isDirectory == true, values.isSymbolicLink == false,
        directory.standardizedFileURL.path == directory.resolvingSymlinksInPath().path
      else { throw BioguideError.invalidDirectory }
      let names = try FileManager.default.contentsOfDirectory(atPath: directory.path)
      let expected = Set(manifest.entries.map(\.filename)).union(["manifest.json"])
      guard Set(names).subtracting(expected).isEmpty,
        Set(manifest.entries.map(\.filename)).isSubset(of: Set(names))
      else { throw BioguideError.invalidDirectory }
    } catch { throw .invalidDirectory }
  }

  private static func isDigest(_ value: String) -> Bool {
    value.utf8.count == 64
      && value.utf8.allSatisfy({ (48...57).contains($0) || (97...102).contains($0) })
  }
}

/// Independent, demand-driven profile reads with bounded memory and exact source bytes.
/// Exhaust the sequence successfully before promoting a snapshot; early break is not validation
/// of the unvisited files. Errors permanently terminate only the affected iterator.
public struct BioguideRecords: AsyncSequence, Sendable {
  /// One verified profile receipt.
  public typealias Element = BioguideRecord
  /// A validation, reading, or cancellation failure.
  public typealias Failure = BioguideError

  /// One traversal retaining an offset, not the whole decoded archive.
  public struct Iterator: AsyncIteratorProtocol {
    /// One verified profile receipt.
    public typealias Element = BioguideRecord
    /// A validation, reading, or cancellation failure.
    public typealias Failure = BioguideError
    private let directory: URL
    private var finished = false
    private let importer: BioguideImporter
    private var index = 0
    init(directory: URL, importer: BioguideImporter) {
      self.directory = directory; self.importer = importer
    }

    /// Reads and validates just the next profile; the first call also reconciles filenames.
    public mutating func next() async throws(BioguideError) -> Element? {
      guard !finished else { return nil }
      finished = true
      guard !Task.isCancelled else { throw .cancelled }
      if index == 0 {
        try await BioguideImporter.validate(directory: directory, manifest: importer.manifest)
      }
      guard index < importer.manifest.entries.count else { return nil }
      let record = try await BioguideImporter.read(
        directory: directory,
        entry: importer.manifest.entries[index], maximumBytes: importer.maximumProfileBytes)
      index += 1; finished = false
      return record
    }
  }

  private let directory: URL
  private let importer: BioguideImporter
  init(directory: URL, importer: BioguideImporter) {
    self.directory = directory; self.importer = importer
  }
  /// Creates an independent traversal without directory or file reads.
  public func makeAsyncIterator() -> Iterator { Iterator(directory: directory, importer: importer) }
}
