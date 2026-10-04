/// A CRS report identifier retained without prefix or case normalization.
public struct CRSReportIdentifier: Hashable, Sendable {
  /// The original safe path component.
  public let rawValue: String

  /// Accepts nonempty ASCII letters, digits, hyphens and underscores.
  ///
  /// This is a path-safety rule, not a provider prefix or length restriction.
  /// - Throws: `CongressInputError.invalidCRSReportIdentifier` for an unsafe component.
  public init(rawValue: String) throws(CongressInputError) {
    guard !rawValue.isEmpty,
      rawValue.utf8.allSatisfy({
        (48...57).contains($0) || (65...90).contains($0) || (97...122).contains($0)
          || $0 == 45 || $0 == 95
      })
    else { throw .invalidCRSReportIdentifier }
    self.rawValue = rawValue
  }
}
