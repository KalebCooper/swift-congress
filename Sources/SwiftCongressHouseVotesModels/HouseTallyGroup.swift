/// One published row of House tally fields, such as the aggregate `totals-by-vote` row or the
/// counts in a `totals-by-party` row.
///
/// ``counts`` holds every direct child element whose local name ends in `-total`, in document
/// order, including repeated and unknown fields. Other elements, such as `total-stub` or a
/// party label, remain only in ``rawNode``. The typed conveniences read the field named by the
/// source element, not by the column header the Clerk prints: the Clerk's vote DTD allows
/// `aye-total` or `yea-total` and `no-total` or `nay-total`, and a historical Aye/No vote can
/// still publish `yea-total` and `nay-total` under `Ayes` and `Noes` header text. Headers remain
/// in ``HouseVoteTallies/rawNode``. A convenience returns nil when its field is absent, and also
/// when the field repeats within this row, so no competing value is picked; ``counts`` keeps
/// every repetition.
///
/// ```swift
/// if let row = rollCall.tallies?.byVote.first {
///   print(row.yea?.rawValue ?? "no yea-total", row.nay?.rawValue ?? "no nay-total")
/// }
/// ```
public struct HouseTallyGroup: Hashable, Sendable {
  /// Every `-total` field in document order, including repeated and unknown fields.
  public let counts: [HouseTallyCount]
  /// The complete source row, including labels, `total-stub`, and unknown elements.
  public let rawNode: HouseXMLNode

  /// The single `aye-total` field; nil when it is absent or repeated in this row.
  ///
  /// This reflects the source element name, not the `Ayes` header text.
  public var aye: HouseTallyCount? { single("aye-total") }
  /// The single `nay-total` field; nil when it is absent or repeated in this row.
  ///
  /// This reflects the source element name, not the `Nays` or `Noes` header text.
  public var nay: HouseTallyCount? { single("nay-total") }
  /// The single `no-total` field; nil when it is absent or repeated in this row.
  ///
  /// This reflects the source element name, not the `Noes` header text.
  public var no: HouseTallyCount? { single("no-total") }
  /// The single `not-voting-total` field; nil when it is absent or repeated in this row.
  public var notVoting: HouseTallyCount? { single("not-voting-total") }
  /// The single `present-total` field; nil when it is absent or repeated in this row.
  public var present: HouseTallyCount? { single("present-total") }
  /// The single `yea-total` field; nil when it is absent or repeated in this row.
  ///
  /// This reflects the source element name, not the `Yeas` or `Ayes` header text.
  public var yea: HouseTallyCount? { single("yea-total") }

  init(node: HouseXMLNode) {
    counts = node.content.compactMap { item in
      if case .element(let child) = item, child.localName.hasSuffix("-total") {
        HouseTallyCount(node: child)
      } else {
        nil
      }
    }
    rawNode = node
  }

  private func single(_ name: String) -> HouseTallyCount? {
    let matches = counts.filter { $0.name == name }
    return matches.count == 1 ? matches.first : nil
  }
}
