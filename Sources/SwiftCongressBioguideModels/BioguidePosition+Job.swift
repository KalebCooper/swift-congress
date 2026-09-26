extension BioguidePosition {
  /// A read-only view of this position's source `job` object.
  ///
  /// Reading the view does not change ``job`` or the position's encoded form.
  /// - Returns: The job view, or nil when `job` is absent, null, or not a JSON object.
  public var jobDetails: BioguideJob? {
    job?.object.map(BioguideJob.init(rawFields:))
  }
}
