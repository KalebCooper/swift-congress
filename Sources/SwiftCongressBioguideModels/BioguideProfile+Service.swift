extension BioguideProfile {
  /// Returns the source positions that satisfy every predicate of a query on the same position.
  ///
  /// Each position is evaluated alone, against its own job and its own Congress affiliation, so a
  /// Congress from one position and a region from another never combine into a match. Matches are
  /// the original values in source order, with duplicates kept and nothing merged or reordered.
  ///
  /// Matching is exact raw equality only. It has no date or as-of semantics: personal service dates
  /// are often missing, and an affiliation's Congress dates describe the body, not the person. The
  /// result reflects this profile as published and makes no claim that the export is complete.
  ///
  /// ```swift
  /// let congress = try BioguideCongressIdentifier(number: 2, type: .usCongress)
  /// for position in profile.positions(matching: BioguideServiceQuery(congress: congress)) {
  ///   print(position.startDate ?? "no published start date")
  /// }
  /// ```
  /// - Parameter query: The predicates one position must satisfy together.
  /// - Returns: The matching positions in source order; empty when none match.
  public func positions(matching query: BioguideServiceQuery) -> [BioguidePosition] {
    jobPositions.filter(query.matches)
  }
}
