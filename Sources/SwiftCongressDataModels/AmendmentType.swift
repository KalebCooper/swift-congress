/// A Congress.gov amendment code, including future provider values.
///
/// ```swift
/// let type: AmendmentType = .houseAmendment
/// ```
public struct AmendmentType: Codable, Hashable, RawRepresentable, Sendable {
  /// A House amendment.
  public static let houseAmendment = Self(rawValue: "hamdt")
  /// A Senate amendment.
  public static let senateAmendment = Self(rawValue: "samdt")
  /// A Senate unprinted amendment; provider coverage is historically limited.
  public static let senateUnprintedAmendment = Self(rawValue: "suamdt")

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
