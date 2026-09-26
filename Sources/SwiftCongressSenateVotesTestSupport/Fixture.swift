import Foundation

package enum Fixture: String {
  /// Recorded https://www.senate.gov/legislative/LIS_MEMBER/cvc_member_data.xml.
  case senate_identities = "senate-identities.xml"
  /// Recorded https://www.senate.gov/legislative/LIS/roll_call_lists/vote_menu_119_2.xml.
  case senate_index = "senate-index.xml"
  /// Recorded https://www.senate.gov/legislative/LIS/roll_call_lists/vote_menu_101_1.xml.
  case senate_index1989 = "senate-index1989.xml"
  /// Recorded https://www.senate.gov/legislative/LIS/roll_call_votes/vote1011/vote_101_1_00001.xml.
  case senate1989 = "senate1989.xml"
  /// Recorded https://www.senate.gov/legislative/LIS/roll_call_votes/vote1112/vote_111_2_00289.xml.
  case senate2010_bill = "senate2010-bill.xml"
  /// Recorded https://www.senate.gov/legislative/LIS/roll_call_votes/vote1112/vote_111_2_00298.xml.
  case senate2010_treaty = "senate2010-treaty.xml"
  /// Recorded https://www.senate.gov/legislative/LIS/roll_call_votes/vote1112/vote_111_2_00297.xml.
  case senate2010_treatyAmendment = "senate2010-treaty-amendment.xml"
  /// Recorded https://www.senate.gov/legislative/LIS/roll_call_votes/vote1192/vote_119_2_00240.xml.
  case senate2026 = "senate2026.xml"

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
