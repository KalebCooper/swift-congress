import Foundation

package enum Fixture: String {
  /// Recorded https://clerk.house.gov/evs/2026/index.asp.
  case house_index = "house-index.html"
  /// Recorded https://clerk.house.gov/evs/1990/index.asp.
  case house_index1990 = "house-index1990.html"
  /// Recorded https://clerk.house.gov/evs/1990/ROLL_000.asp.
  case house_section1990 = "house-section1990.html"
  /// Recorded https://clerk.house.gov/evs/2026/ROLL_300.asp.
  case house_section2026 = "house-section2026.html"
  /// Recorded https://clerk.house.gov/evs/1990/roll001.xml.
  case house1990 = "house1990.xml"
  /// Recorded https://clerk.house.gov/evs/1990/roll010.xml.
  case house1990_vote = "house1990-vote.xml"
  /// Recorded https://clerk.house.gov/evs/2025/roll002.xml.
  case house2025_speaker = "house2025-speaker.xml"
  /// Recorded https://clerk.house.gov/evs/2026/roll314.xml.
  case house2026 = "house2026.xml"

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
