/// One published `totals-by-party` row of a House roll call.
///
/// The party label is the Clerk's text exactly, such as `Republican` or `Independent`; it is not
/// a party code, a member identifier, or a count of seats. Rows keep document order, and a row
/// whose counts are all zero is still a published row.
///
/// ```swift
/// for row in rollCall.tallies?.byParty ?? [] {
///   print(row.party ?? "unlabeled", row.counts.yea?.rawValue ?? "no yea-total")
/// }
/// ```
public struct HousePartyTally: Hashable, Sendable {
  /// The `-total` fields published in this row.
  public let counts: HouseTallyGroup
  /// The single `party` element's text; nil when it is absent or repeated in this row.
  public let party: String?
  /// The complete source row, including unknown elements.
  public let rawNode: HouseXMLNode

  init(node: HouseXMLNode) {
    counts = HouseTallyGroup(node: node)
    let labels = node.children(named: "party")
    party = labels.count == 1 ? labels.first?.text : nil
    rawNode = node
  }
}
