/// A built-in collection whose returned rows track a separately published total.
/// Consumer collections retain the generic pagination count contract.
protocol CongressPageCount {
  var continuationCount: Int { get }
}
