// Bundle resource loading requires Foundation on portable platforms.
import Foundation

package enum Fixture: String {
  /// Recorded https://api.congress.gov/v3/bill/119/hr/1/actions?format=json&limit=250.
  case actions119 = "actions119.json"
  /// Recorded https://api.congress.gov/v3/bill/119/hr/1?format=json.
  case bill119 = "bill119.json"
  /// Recorded https://api.congress.gov/v3/bill/6/hr/1?format=json.
  case bill6 = "bill6.json"
  /// Recorded https://api.congress.gov/v3/bill/82/s/677?format=json.
  case bill82 = "bill82.json"
  /// Recorded https://api.congress.gov/v3/bill/6?format=json&limit=2&offset=0.
  case bills6_first = "bills6-first.json"
  /// Recorded https://api.congress.gov/v3/bill/6?offset=2&limit=2&format=json.
  case bills6_next = "bills6-next.json"
  /// Recorded https://api.congress.gov/v3/congress?format=json&limit=2&offset=0.
  case congresses_first = "congresses-first.json"
  /// Recorded https://api.congress.gov/v3/congress?offset=118&limit=2&format=json.
  case congresses_last = "congresses-last.json"
  /// Recorded https://api.congress.gov/v3/congress?offset=2&limit=2&format=json.
  case congresses_next = "congresses-next.json"

  package func data() throws -> Data {
    guard
      let url = Bundle.module.url(
        forResource: rawValue, withExtension: nil, subdirectory: "Fixtures")
    else {
      throw CocoaError(.fileNoSuchFile)
    }
    return try Data(contentsOf: url)
  }
}

package let suiteTimeLimitMinutes = 1
