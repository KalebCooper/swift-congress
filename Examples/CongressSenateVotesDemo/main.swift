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
    print(value.question ?? "Question unavailable")
    if let subject = value.subject {
      switch subject {
      case .amendment(let amendment):
        print("Subject: amendment \(amendment.number)")
        print("Target label: \(amendment.targetDocumentNumber ?? "none published")")
        if let target = amendment.target {
          switch target {
          case .bill(let measureType, let number):
            print("Parsed target: \(measureType.rawValue) \(number)")
          case .treaty(let number):
            print("Parsed target: Treaty Doc. \(number)")
          case .unknown(let label):
            print("Parsed target: unrecognized \(label)")
          }
        } else {
          print("Parsed target: none published")
        }
      case .bill(let bill):
        print("Subject: bill \(bill.measureType.rawValue) \(bill.number ?? "no number")")
      case .nomination(let nomination):
        print("Subject: nomination PN \(nomination.number ?? "no number")")
      case .treaty(let treaty):
        print("Subject: treaty Treaty Doc. \(treaty.number ?? "no number")")
      case .unknown(let unknown):
        print("Subject: unrecognized (\(unknown.reason))")
      }
    } else {
      print("Subject: none published")
    }
    print("LIS voter identities are not resolved by this demo.")
  }
  enum DemoError: Error { case arguments }
}
