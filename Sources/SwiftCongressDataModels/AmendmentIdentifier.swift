/// A validated amendment key without a historical coverage cutoff.
public struct AmendmentIdentifier: Hashable, Sendable {
  /// The positive source Congress number.
  public let congress: Int
  /// The positive ASCII decimal amendment number, preserved as supplied.
  public let number: String
  /// The safe open amendment code, normalized to lowercase for requests.
  public let type: AmendmentType

  /// Validates path components without imposing a historical coverage cutoff.
  /// - Throws: `CongressInputError.invalidAmendmentIdentifier` for unsafe components.
  public init(congress: Int, number: String, type: AmendmentType) throws(CongressInputError) {
    guard congress > 0, !number.isEmpty, number.utf8.allSatisfy({ (48...57).contains($0) }),
      number.contains(where: { $0 != "0" }), !type.rawValue.isEmpty,
      type.rawValue.utf8.allSatisfy({ (65...90).contains($0) || (97...122).contains($0) })
    else { throw .invalidAmendmentIdentifier }
    self.congress = congress
    self.number = number
    self.type = AmendmentType(rawValue: type.rawValue.lowercased())
  }
}
