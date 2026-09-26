extension HouseRollCall {
  /// The published tally rows, read from ``rawNode`` on each access.
  ///
  /// Returns nil when the document has no `vote-totals` element in `vote-metadata`. The Clerk's
  /// vote DTD permits one; if a document repeats it, the first is used, matching ``totals``.
  /// Reading this property changes no stored value and no `Codable` output.
  ///
  /// ```swift
  /// let yeas = rollCall.tallies?.byVote.first?.yea?.value
  /// ```
  public var tallies: HouseVoteTallies? {
    rawNode.child("vote-metadata")?.child("vote-totals").map(HouseVoteTallies.init(node:))
  }
}
