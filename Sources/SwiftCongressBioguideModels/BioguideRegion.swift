/// A read-only view of a Bioguide affiliation's source `represents` object.
///
/// The view is derived from the retained JSON and never replaces it: ``BioguideAffiliation/represents``
/// keeps the original value, and ``rawFields`` keeps every key of the object, including unknown
/// ones. A field that is absent, null, or not a string reads as nil here. The export publishes a
/// state or territory code even for a `DistrictRegion`; no district number is inferred.
///
/// ```swift
/// if let region = position.congressAffiliation?.representedRegion {
///   print(region.regionType ?? "no region type", region.regionCode ?? "no region code")
/// }
/// ```
public struct BioguideRegion: Hashable, Sendable {
  /// Every field of the source `represents` object, including unknown keys and explicit nulls.
  public let rawFields: [String: JSONValue]
  /// The source `regionCode` string, such as `PA`; nil when absent or not a string.
  public let regionCode: String?
  /// The source `regionType` string, such as `StateRegion`; nil when absent or not a string.
  public let regionType: String?

  init(rawFields: [String: JSONValue]) {
    self.rawFields = rawFields
    regionCode = rawFields["regionCode"]?.string
    regionType = rawFields["regionType"]?.string
  }
}
