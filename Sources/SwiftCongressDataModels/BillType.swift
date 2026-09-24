/// A Congress.gov bill or resolution code, including future provider values.
///
/// ```swift
/// let type: BillType = .houseBill
/// ```
public struct BillType: Codable, Hashable, RawRepresentable, Sendable {
  /// A House bill.
  public static let houseBill = Self(rawValue: "hr")
  /// A House concurrent resolution.
  public static let houseConcurrentResolution = Self(rawValue: "hconres")
  /// A House joint resolution.
  public static let houseJointResolution = Self(rawValue: "hjres")
  /// A House resolution.
  public static let houseResolution = Self(rawValue: "hres")
  /// A Senate bill.
  public static let senateBill = Self(rawValue: "s")
  /// A Senate concurrent resolution.
  public static let senateConcurrentResolution = Self(rawValue: "sconres")
  /// A Senate joint resolution.
  public static let senateJointResolution = Self(rawValue: "sjres")
  /// A Senate resolution.
  public static let senateResolution = Self(rawValue: "sres")

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
