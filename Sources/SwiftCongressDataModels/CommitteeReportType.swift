/// A Congress.gov committee report code, including future provider values.
///
/// ```swift
/// let type: CommitteeReportType = .houseReport
/// ```
public struct CommitteeReportType: Codable, Hashable, RawRepresentable, Sendable {
  /// An executive report.
  public static let executiveReport = Self(rawValue: "erpt")
  /// A House report.
  public static let houseReport = Self(rawValue: "hrpt")
  /// A Senate report.
  public static let senateReport = Self(rawValue: "srpt")

  /// The exact source spelling; request identifiers validate it separately.
  public let rawValue: String

  /// Preserves a provider code without closing the vocabulary.
  /// - Parameter rawValue: The source value.
  public init(rawValue: String) { self.rawValue = rawValue }

  /// Decodes a single source string.
  public init(from decoder: any Decoder) throws {
    rawValue = try decoder.singleValueContainer().decode(String.self)
  }

  /// Encodes the exact source string.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}
