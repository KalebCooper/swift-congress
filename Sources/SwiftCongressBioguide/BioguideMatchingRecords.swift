import SwiftCongressBioguideModels

/// Independent, demand-driven reads of the verified profiles that publish a matching position.
///
/// Each call to `next()` reads and verifies profiles in manifest order until one has at least one
/// position satisfying the query, and yields that profile's complete original record once, however
/// many of its positions match. A profile with no positions never matches, even an empty query;
/// use ``BioguideRecords`` for every profile. Profiles that do not match are still fully verified:
/// a corrupt, undecodable, or mismatched profile throws even when it would not have matched.
/// Nothing is read ahead, and only the record under evaluation is held in memory.
///
/// Filtering has the same exact raw-equality semantics as `BioguideProfile.positions(matching:)`
/// and no date or as-of semantics. A finished traversal lists the matching profiles of the supplied
/// export only; it makes no claim that the export is complete. Errors permanently terminate only
/// the affected iterator.
///
/// ```swift
/// let congress = try BioguideCongressIdentifier(number: 2, type: .continentalCongress)
/// let query = BioguideServiceQuery(congress: congress, job: .delegate)
/// for try await record in importer.records(in: directory, matching: query) {
///   print(record.profile.usCongressBioId)
/// }
/// ```
public struct BioguideMatchingRecords: AsyncSequence, Sendable {
  /// One verified profile receipt with at least one matching position.
  public typealias Element = BioguideRecord
  /// A validation, reading, or cancellation failure.
  public typealias Failure = BioguideError

  /// One traversal retaining a manifest offset and the query, not the matching records.
  public struct Iterator: AsyncIteratorProtocol {
    /// One verified profile receipt with at least one matching position.
    public typealias Element = BioguideRecord
    /// A validation, reading, or cancellation failure.
    public typealias Failure = BioguideError
    private var finished = false
    private let query: BioguideServiceQuery
    private var records: BioguideRecords.Iterator
    init(query: BioguideServiceQuery, records: BioguideRecords.Iterator) {
      self.query = query; self.records = records
    }

    /// Reads and verifies profiles in manifest order until one matches.
    ///
    /// Cancellation is checked before every profile read, including between skipped profiles.
    /// - Returns: The next matching record, or nil when the manifest is exhausted or after a failure.
    /// - Throws: `BioguideError.cancelled` when the task is cancelled; `.invalidDirectory`,
    ///   `.corruptProfile`, `.decoding`, or `.mismatchedIdentifier` for any scanned profile,
    ///   matching or not.
    public mutating func next() async throws(BioguideError) -> Element? {
      guard !finished else { return nil }
      finished = true
      while true {
        guard !Task.isCancelled else { throw .cancelled }
        guard let record = try await records.next() else { return nil }
        if !record.profile.positions(matching: query).isEmpty {
          finished = false
          return record
        }
      }
    }
  }

  private let query: BioguideServiceQuery
  private let records: BioguideRecords
  init(query: BioguideServiceQuery, records: BioguideRecords) {
    self.query = query; self.records = records
  }
  /// Creates an independent traversal without directory or file reads.
  public func makeAsyncIterator() -> Iterator {
    Iterator(query: query, records: records.makeAsyncIterator())
  }
}
