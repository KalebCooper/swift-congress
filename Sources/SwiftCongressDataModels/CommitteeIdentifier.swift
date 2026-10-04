/// A committee request identity, independent of an optional Congress scope.
public struct CommitteeIdentifier: Hashable, Sendable {
  /// The request chamber; never inferred from the code.
  public let chamber: CommitteeChamber
  /// The original safe source code.
  public let code: String

  /// Accepts nonempty ASCII letters, digits, hyphens and underscores.
  ///
  /// This validates path safety without inferring a prefix, parent or code length.
  /// - Throws: `CongressInputError.invalidCommitteeIdentifier` for unsafe codes.
  public init(chamber: CommitteeChamber, code: String) throws(CongressInputError) {
    guard !code.isEmpty,
      code.utf8.allSatisfy({
        (48...57).contains($0) || (65...90).contains($0) || (97...122).contains($0)
          || $0 == 45 || $0 == 95
      })
    else { throw .invalidCommitteeIdentifier }
    self.chamber = chamber
    self.code = code
  }
}
