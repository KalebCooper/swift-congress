/// The kind of legislative body a Bioguide Congress affiliation names, including future source values.
///
/// The export distinguishes the U.S. Congress from its predecessor bodies. The same number in two
/// bodies names two different Congresses, so a type is always compared together with its number.
/// Unknown source spellings are preserved rather than rejected.
///
/// ```swift
/// let type: BioguideCongressType = .continentalCongress
/// let unknown = BioguideCongressType(rawValue: "ProvincialCongress")
/// ```
public struct BioguideCongressType: Hashable, RawRepresentable, Sendable {
  /// The Congress of the Confederation, published as `ConfederationCongress`.
  public static let confederationCongress = Self(rawValue: "ConfederationCongress")
  /// The Continental Congress, published as `ContinentalCongress`.
  public static let continentalCongress = Self(rawValue: "ContinentalCongress")
  /// The United States Congress, published as `USCongress`.
  public static let usCongress = Self(rawValue: "USCongress")

  /// The exact source spelling, compared case-sensitively.
  public let rawValue: String

  /// Preserves a source body type without closing the vocabulary.
  /// - Parameter rawValue: The source `congressType` value.
  public init(rawValue: String) { self.rawValue = rawValue }
}
