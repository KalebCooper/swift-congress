// Internal because only verified built-in envelopes may count non-item source records.
protocol CongressPageRecords {
  var consumedRecordCount: Int { get }
}
