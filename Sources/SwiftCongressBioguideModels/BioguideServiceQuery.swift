/// Source-service predicates that one Bioguide job position must satisfy together.
///
/// Each predicate is optional. A predicate that is set matches only when the position publishes the
/// corresponding evidence and it is exactly equal, case-sensitively, to the queried raw value:
/// the Congress number and body type of the position's own affiliation, the position's own job name,
/// and the region code its own affiliation represents. Missing evidence never matches a set
/// predicate. A query with no predicates matches every position.
///
/// The query answers which published positions carry these values. It has no date or as-of
/// semantics, infers no chamber or identity, and says nothing about the completeness of the export.
///
/// ```swift
/// let congress = try BioguideCongressIdentifier(congressType: .continentalCongress, number: 2)
/// let query = BioguideServiceQuery(congress: congress, job: .delegate, regionCode: "PA")
/// let positions = profile.positions(matching: query)
/// ```
public struct BioguideServiceQuery: Hashable, Sendable {
  /// The Congress the position's affiliation must name, or nil for any.
  public let congress: BioguideCongressIdentifier?
  /// The job name the position must publish, or nil for any.
  public let job: BioguideJobName?
  /// The exact represented region code the position's affiliation must publish, or nil for any.
  public let regionCode: String?

  /// Creates a query from optional same-position predicates.
  /// - Parameters:
  ///   - congress: The Congress and body the affiliation must name, or nil for any.
  ///   - job: The source job name the position must publish, or nil for any.
  ///   - regionCode: The exact source region code, such as `PA`, or nil for any.
  public init(
    congress: BioguideCongressIdentifier? = nil, job: BioguideJobName? = nil,
    regionCode: String? = nil
  ) {
    self.congress = congress
    self.job = job
    self.regionCode = regionCode
  }

  func matches(_ position: BioguidePosition) -> Bool {
    let affiliation = position.congressAffiliation
    if let congress {
      guard let source = affiliation?.congress, source.congressNumber == congress.number,
        source.congressType == congress.congressType.rawValue
      else { return false }
    }
    if let job, position.jobDetails?.name != job { return false }
    if let regionCode, affiliation?.representedRegion?.regionCode != regionCode { return false }
    return true
  }
}
