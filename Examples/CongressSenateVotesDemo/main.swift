import Foundation
import SwiftCongressSenateVotes
import SwiftCongressSenateVotesModels

@main
struct CongressSenateVotesDemo {
  static func main() async throws {
    let arguments = Array(CommandLine.arguments.dropFirst())
    guard arguments.count == 1 else { throw DemoError.arguments }
    let value: SenateRollCall
    if arguments[0] == "--live" {
      #if canImport(Darwin)
      value = try await SenateVotesClient(userAgent: "CongressSenateVotesDemo/1.0").rollCall(
        congress: 101, number: 1, session: 1)
      #else
      throw DemoError.arguments
      #endif
    } else {
      let url = URL(fileURLWithPath: arguments[0])
      value = try SenateRollCall.decode(Data(contentsOf: url), sourceURL: url)
    }
    print(
      "Senate Congress \(value.identifier.congress), session \(value.identifier.session), vote \(value.identifier.number): \(value.recordedVoters.count) recorded rows"
    )
    print(value.title ?? "Title unavailable")
  }
  enum DemoError: Error { case arguments }
}
