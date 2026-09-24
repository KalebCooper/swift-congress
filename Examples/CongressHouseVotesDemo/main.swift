import Foundation
import SwiftCongressHouseVotes
import SwiftCongressHouseVotesModels

@main
struct CongressHouseVotesDemo {
  static func main() async throws {
    let arguments = Array(CommandLine.arguments.dropFirst())
    guard arguments.count == 1 else { throw DemoError.arguments }
    let value: HouseRollCall
    if arguments[0] == "--live" {
      #if canImport(Darwin)
      value = try await HouseVotesClient(userAgent: "CongressHouseVotesDemo/1.0").rollCall(
        number: 314, year: 2026)
      #else
      throw DemoError.arguments
      #endif
    } else {
      let url = URL(fileURLWithPath: arguments[0])
      value = try HouseRollCall.decode(Data(contentsOf: url), sourceURL: url)
    }
    print(
      "House Congress \(value.congress), roll \(value.number): \(value.recordedVoters.count) recorded rows"
    )
    print(value.question ?? "Question unavailable")
  }
  enum DemoError: Error { case arguments }
}
