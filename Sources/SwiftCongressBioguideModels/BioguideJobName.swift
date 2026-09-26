/// The name of a Bioguide job position, including leadership and future source values.
///
/// The constants cover the member jobs a historical-service query commonly names. The export also
/// publishes leadership and other job names, such as `Speaker Of The House`; those remain available
/// through ``init(rawValue:)`` with their exact source spelling. A job name does not establish a
/// chamber: a Delegate to the Continental Congress is not a modern House member.
///
/// ```swift
/// let job: BioguideJobName = .residentCommissioner
/// let leadership = BioguideJobName(rawValue: "Speaker Of The House")
/// ```
public struct BioguideJobName: Hashable, RawRepresentable, Sendable {
  /// A Delegate, published as `Delegate`.
  public static let delegate = Self(rawValue: "Delegate")
  /// A Representative, published as `Representative`.
  public static let representative = Self(rawValue: "Representative")
  /// A Resident Commissioner, published as `Resident Commissioner`.
  public static let residentCommissioner = Self(rawValue: "Resident Commissioner")
  /// A Senator, published as `Senator`.
  public static let senator = Self(rawValue: "Senator")

  /// The exact source spelling, compared case-sensitively.
  public let rawValue: String

  /// Preserves a source job name without closing the vocabulary.
  /// - Parameter rawValue: The source `job.name` value.
  public init(rawValue: String) { self.rawValue = rawValue }
}
