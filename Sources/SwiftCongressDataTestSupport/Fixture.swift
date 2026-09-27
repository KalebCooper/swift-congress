// Bundle resource loading requires Foundation on portable platforms.
import Foundation

package enum Fixture: String {
  /// Recorded https://api.congress.gov/v3/bill/119/hr/1/actions?format=json&limit=250.
  case actions119 = "actions119.json"
  /// Recorded https://api.congress.gov/v3/bill/119/hr/1?format=json.
  case bill119 = "bill119.json"
  /// Recorded https://api.congress.gov/v3/bill/119/hr/1/text?format=json&limit=2&offset=0.
  case bill119_text_first = "bill119-text-first.json"
  /// Recorded https://api.congress.gov/v3/bill/119/hr/1/text?offset=2&limit=2&format=json.
  case bill119_text_next = "bill119-text-next.json"
  /// Recorded https://api.congress.gov/v3/bill/119/hr/1/text?offset=4&limit=2&format=json.
  case bill119_text_offset4 = "bill119-text-offset4.json"
  /// Recorded https://api.congress.gov/v3/bill/119/hr/1/text?offset=5&limit=2&format=json.
  case bill119_text_terminal = "bill119-text-terminal.json"
  /// Recorded https://api.congress.gov/v3/bill/6/hr/1?format=json.
  case bill6 = "bill6.json"
  /// Recorded https://api.congress.gov/v3/bill/6/hr/1/text?format=json.
  case bill6_text = "bill6-text.json"
  /// Recorded https://api.congress.gov/v3/bill/82/s/677?format=json.
  case bill82 = "bill82.json"
  /// Recorded https://api.congress.gov/v3/bill/82/s/677/text?format=json.
  case bill82_text = "bill82-text.json"
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
  /// Recorded https://api.congress.gov/v3/member/A000375?format=json.
  case member_A000375 = "member-A000375.json"
  /// Recorded https://api.congress.gov/v3/member/H000324?format=json.
  case member_H000324 = "member-H000324.json"
  /// Recorded https://api.congress.gov/v3/member/L000174?format=json.
  case member_L000174 = "member-L000174.json"
  /// Recorded https://api.congress.gov/v3/member/P000610?format=json.
  case member_P000610 = "member-P000610.json"
  /// Recorded https://api.congress.gov/v3/member/congress/117?currentMember=true&format=json&limit=2&offset=0.
  case members117_current = "members117-current.json"
  /// Recorded https://api.congress.gov/v3/member/congress/117?currentMember=false&format=json&limit=2&offset=0.
  case members117_first = "members117-first.json"
  /// Recorded https://api.congress.gov/v3/member/congress/117?currentMember=false&offset=2&limit=2&format=json.
  case members117_next = "members117-next.json"
  /// Recorded https://api.congress.gov/v3/member/congress/117?currentMember=false&offset=556&limit=2&format=json.
  case members117_terminal = "members117-terminal.json"
  /// Recorded https://api.congress.gov/v3/member?currentMember=false&format=json&limit=2&offset=0.
  case members_default_first = "members-default-first.json"
  /// Recorded https://api.congress.gov/v3/member?currentMember=false&offset=2&limit=2&format=json.
  case members_default_next = "members-default-next.json"
  /// Recorded https://api.congress.gov/v3/member?format=json&limit=2&offset=0.
  case members_first = "members-first.json"
  /// Recorded https://api.congress.gov/v3/member?format=json&fromDateTime=2026-09-01T00:00:00Z&limit=2&offset=0&toDateTime=2026-09-25T00:00:00Z.
  case members_window = "members-window.json"

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
