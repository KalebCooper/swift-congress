/// A validated standalone report key, independent of any report part.
public struct CommitteeReportIdentifier: Hashable, Sendable {
  /// The positive source Congress number.
  public let congress: Int
  /// The positive ASCII decimal report number, preserved as supplied.
  public let number: String
  /// The safe open report code, normalized to lowercase for requests.
  public let type: CommitteeReportType

  /// Validates path components without imposing a historical coverage cutoff.
  /// - Throws: `CongressInputError.invalidCommitteeReportIdentifier` for unsafe components.
  public init(congress: Int, number: String, type: CommitteeReportType) throws(CongressInputError) {
    guard congress > 0, !number.isEmpty, number.utf8.allSatisfy({ (48...57).contains($0) }),
      number.contains(where: { $0 != "0" }), !type.rawValue.isEmpty,
      type.rawValue.utf8.allSatisfy({ (65...90).contains($0) || (97...122).contains($0) })
    else { throw .invalidCommitteeReportIdentifier }
    self.congress = congress
    self.number = number
    self.type = CommitteeReportType(rawValue: type.rawValue.lowercased())
  }
}
