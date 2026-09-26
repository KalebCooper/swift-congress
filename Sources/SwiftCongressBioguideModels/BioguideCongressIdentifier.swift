/// A failure to construct a Bioguide query input.
public enum BioguideInputError: Error, Hashable, Sendable {
  /// A Congress number is less than 1.
  case invalidCongress
}

/// A numbered Congress within one legislative body, as the Bioguide export identifies it.
///
/// The number is meaningful only with its body type: the 2nd Continental Congress and the 2nd
/// United States Congress are different identifiers and never compare equal. No upper bound is
/// imposed, so a future Congress remains expressible. The identifier asserts nothing about dates,
/// membership, or coverage of the export.
///
/// ```swift
/// let continental = try BioguideCongressIdentifier(number: 2, type: .continentalCongress)
/// let federal = try BioguideCongressIdentifier(number: 2, type: .usCongress)
/// assert(continental != federal)
/// ```
public struct BioguideCongressIdentifier: Hashable, Sendable {
  /// The positive Congress number within its body.
  public let number: Int
  /// The body the number counts within.
  public let type: BioguideCongressType

  /// Creates a Congress identity for comparison with source affiliations.
  /// - Parameters:
  ///   - number: The Congress number within its body, 1 or greater.
  ///   - type: The source body type; unknown types are accepted unchanged.
  /// - Throws: `BioguideInputError.invalidCongress` when `number` is less than 1.
  public init(number: Int, type: BioguideCongressType) throws(BioguideInputError) {
    guard number >= 1 else { throw .invalidCongress }
    self.number = number
    self.type = type
  }
}
