/// A law lookup key, distinct from the identity of its originating bill or resolution.
public struct LawIdentifier: Hashable, Sendable {
  /// The positive U.S. Congress number.
  public let congress: Int
  /// The positive decimal law number within its Congress and category.
  public let number: String
  /// The documented public or private law route category.
  public let type: LawType

  /// Validates a law key without imposing a historical cutoff or converting it to a bill key.
  /// - Parameters:
  ///   - congress: A positive Congress number.
  ///   - number: A positive ASCII decimal law number, preserved as supplied.
  ///   - type: The public or private law category.
  /// - Throws: `CongressInputError.invalidLawIdentifier` for an invalid Congress or number.
  public init(congress: Int, number: String, type: LawType) throws(CongressInputError) {
    guard congress > 0, !number.isEmpty, number.utf8.allSatisfy({ (48...57).contains($0) }),
      number.contains(where: { $0 != "0" })
    else { throw .invalidLawIdentifier }
    self.congress = congress
    self.number = number
    self.type = type
  }
}
