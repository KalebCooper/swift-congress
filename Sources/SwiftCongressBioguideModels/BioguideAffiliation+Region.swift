extension BioguideAffiliation {
  /// A read-only view of this affiliation's source `represents` object.
  ///
  /// Reading the view does not change ``represents`` or the affiliation's encoded form.
  /// - Returns: The region view, or nil when `represents` is absent, null, or not a JSON object.
  public var representedRegion: BioguideRegion? {
    represents?.object.map(BioguideRegion.init(rawFields:))
  }
}
