/// Invalid Congress.gov request input.
public enum CongressInputError: Error, Hashable, Sendable {
  /// A bill identifier has an invalid Congress, code, or number.
  case invalidBillIdentifier
  /// A member identifier is empty or is not a safe path component.
  case invalidMemberIdentifier
  /// A query contains an invalid page size, offset, or Congress.
  case invalidQuery
}

/// A source-numbered bill identity. Early surrogate identifiers use BillSourceIdentifier.
public struct BillIdentifier: Hashable, Sendable {
  /// The validated Congress.gov key.
  public let source: BillSourceIdentifier

  /// Creates an identity for a numbered bill.
  /// - Parameters:
  ///   - congress: The U.S. Congress, 15 or later; earlier records use source identifiers.
  ///   - number: The positive decimal bill number.
  ///   - type: The bill or resolution code.
  /// - Throws: `CongressInputError.invalidBillIdentifier` for an invalid or early key.
  public init(congress: Int, number: String, type: BillType) throws(CongressInputError) {
    guard congress >= 15 else { throw .invalidBillIdentifier }
    source = try BillSourceIdentifier(congress: congress, number: number, type: type)
  }
}

/// A Congress.gov record key whose number may be a historical surrogate.
/// This value never asserts an official bill number or historical collection completeness.
public struct BillSourceIdentifier: Hashable, Sendable {
  /// The positive U.S. Congress number.
  public let congress: Int
  /// The source's decimal record number, which may be a surrogate.
  public let number: String
  /// The normalized request code.
  public let type: BillType

  /// Validates a source key without promoting it to an official bill identity.
  /// - Throws: `CongressInputError.invalidBillIdentifier` for invalid components.
  public init(congress: Int, number: String, type: BillType) throws(CongressInputError) {
    guard congress > 0, !number.isEmpty, number.utf8.allSatisfy({ (48...57).contains($0) }),
      number.contains(where: { $0 != "0" }), !type.rawValue.isEmpty,
      type.rawValue.utf8.allSatisfy({ (65...90).contains($0) || (97...122).contains($0) })
    else { throw .invalidBillIdentifier }
    self.congress = congress
    self.number = number
    self.type = BillType(rawValue: type.rawValue.lowercased())
  }
}
