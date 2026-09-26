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
    if let reference = value.legislationReference {
      print("Legislation: \(reference.rawValue)")
      if let measure = reference.measure {
        print(
          "Recognized measure: \(measure.measureType.rawValue) \(measure.number) (Congress \(measure.congress))"
        )
      } else {
        print("Recognized measure: none")
      }
    } else {
      print("Legislation: none published")
    }
    if let tallies = value.tallies {
      for row in tallies.byVote {
        for count in row.counts {
          let display = count.value.map(String.init) ?? "raw: \(count.rawValue)"
          print("Vote total \(count.name): \(display)")
        }
      }
    } else {
      print("Vote totals: none published")
    }
  }
  enum DemoError: Error { case arguments }
}
