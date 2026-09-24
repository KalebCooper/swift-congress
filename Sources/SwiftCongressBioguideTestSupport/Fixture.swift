import Foundation

package enum Fixture: String {
  /// A000375.json from the official all-profile archive identified in manifest.json.
  case current = "A000375.json"
  /// M000985.json from the same archive, including Continental Congress service.
  case historical = "M000985.json"
  /// H000619.json from the same archive, without structured member service.
  case noService = "H000619.json"
  /// B001323.json from the same archive, retaining restricted portrait rights.
  case restricted = "B001323.json"

  package static func directory() throws -> URL {
    guard let directory = Bundle.module.url(forResource: "Fixtures", withExtension: nil) else {
      throw CocoaError(.fileNoSuchFile)
    }
    return directory
  }
  package func data() throws -> Data {
    try Data(contentsOf: Self.directory().appendingPathComponent(rawValue))
  }
}
package let suiteTimeLimitMinutes = 1
