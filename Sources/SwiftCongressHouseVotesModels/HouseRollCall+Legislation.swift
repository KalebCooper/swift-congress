extension HouseRollCall {
  /// The published `legis-num` label and its conservative reading, computed on each access.
  ///
  /// Returns nil when the document has no `legis-num`, as in an election of the Speaker. The
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
