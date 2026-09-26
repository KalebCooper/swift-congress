/// The typed rows of a House roll call's published `vote-totals` element.
///
/// Each array holds the matching direct child rows in document order, repeated rows included, so
/// nothing is collapsed into a dictionary. A present but empty `vote-totals` element yields empty
/// arrays. Which arrays have rows depends on the vote: an ordinary roll call publishes party rows
/// and one aggregate row, while an election of the Speaker publishes candidate rows only. The
/// party header labels and any unknown row kinds remain in ``rawNode``. These rows are the
/// Clerk's published aggregates; none is computed from voter rows.
///
/// ```swift
/// if let tallies = rollCall.tallies {
///   for row in tallies.byParty {
///     print(row.party ?? "unlabeled", row.counts.yea?.rawValue ?? "no yea-total")
///   }
/// }
/// ```
public struct HouseVoteTallies: Hashable, Sendable {
  /// Every `totals-by-candidate` row in document order.
  public let byCandidate: [HouseCandidateTally]
  /// Every `totals-by-party` row in document order.
  public let byParty: [HousePartyTally]
  /// Every `totals-by-vote` row in document order; the Clerk's vote DTD publishes at most one.
  public let byVote: [HouseTallyGroup]
  /// The complete `vote-totals` element, including headers and unknown rows.
  public let rawNode: HouseXMLNode

  init(node: HouseXMLNode) {
    byCandidate = node.children(named: "totals-by-candidate").map(HouseCandidateTally.init(node:))
    byParty = node.children(named: "totals-by-party").map(HousePartyTally.init(node:))
    byVote = node.children(named: "totals-by-vote").map(HouseTallyGroup.init(node:))
    rawNode = node
  }
}
