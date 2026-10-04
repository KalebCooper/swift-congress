/// Supported request chambers. Response chamber labels remain open strings.
public enum CommitteeChamber: String, CaseIterable, Hashable, Sendable {
  /// House committees.
  case house
  /// Joint committees and commissions.
  case joint
  /// Senate committees.
  case senate
}
