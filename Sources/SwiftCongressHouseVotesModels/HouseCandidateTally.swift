/// One published `totals-by-candidate` row, as in an election of the Speaker.
///
/// The candidate label is the Clerk's text exactly, such as `Johnson (LA)`. It is not a member
/// identifier, and a row can be a literal `Present` or `Not Voting` label rather than a person,
/// so candidate counts are not interchangeable with votes for people. This describes a chamber
/// proceeding, not electoral or campaign data.
///
/// ```swift
/// for row in rollCall.tallies?.byCandidate ?? [] {
///   print(row.candidate ?? "unlabeled", row.count?.rawValue ?? "no candidate-total")
/// }
/// ```
public struct HouseCandidateTally: Hashable, Sendable {
  /// The single `candidate` element's text; nil when it is absent or repeated in this row.
  public let candidate: String?
  /// The single `candidate-total` field; nil when it is absent or repeated in this row.
  public let count: HouseTallyCount?
  /// The complete source row, including unknown elements.
  public let rawNode: HouseXMLNode

  init(node: HouseXMLNode) {
    let labels = node.children(named: "candidate")
    candidate = labels.count == 1 ? labels.first?.text : nil
    let totals = node.children(named: "candidate-total")
    count = totals.count == 1 ? totals.first.map(HouseTallyCount.init(node:)) : nil
    rawNode = node
  }
}
