extension HouseRollCall {
  /// The published `legis-num` label and its conservative reading, computed on each access.
  ///
  /// Returns nil when the document has no `legis-num`, as in an election of the Speaker, and also
  /// when the DTD's optional element is published instead as `vote-issue` (a nomination number or
  /// `n/a` when the item voted on is not legislation); check
  /// `rawNode.child("vote-metadata")?.child("vote-issue")` to tell the two cases apart. The
  /// label is the same text as ``legislation``, so a repeated `legis-num` uses the first, and the
  /// Congress is this roll call's own ``congress``. Reading this property changes no stored
  /// value and no `Codable` output. See ``HouseLegislationReference`` for exactly which labels
  /// yield a ``HouseLegislationReference/measure``.
  ///
  /// ```swift
  /// let number = rollCall.legislationReference?.measure?.number
  /// ```
  public var legislationReference: HouseLegislationReference? {
    legislation.map { HouseLegislationReference(congress: congress, rawValue: $0) }
  }
}
