/// A Congress.gov member identifier, preserved exactly as supplied.
///
/// ```swift
/// let identifier = try MemberIdentifier(rawValue: "L000174")
/// ```
public struct MemberIdentifier: Hashable, Sendable {
  /// The identifier as supplied, without case or length normalization.
  public let rawValue: String

  /// Validates an identifier as a safe path component.
  ///
  /// The accepted characters are ASCII letters, digits, hyphen, and underscore. That is the
  /// path-component set this module sends, not a statement of the provider's identifier format.
  /// - Parameter rawValue: The identifier to send in the member route.
  /// - Throws: `CongressInputError.invalidMemberIdentifier` for an empty value or any other
  ///   character, including slashes, dots, percent signs, spaces, and controls.
  public init(rawValue: String) throws(CongressInputError) {
    guard !rawValue.isEmpty,
      rawValue.utf8.allSatisfy({
        (48...57).contains($0) || (65...90).contains($0) || (97...122).contains($0)
          || $0 == 45 || $0 == 95
      })
    else { throw .invalidMemberIdentifier }
    self.rawValue = rawValue
  }
}
