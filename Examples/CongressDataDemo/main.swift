import Foundation
import SwiftCongressData
import SwiftCongressDataModels

// Offline: pass a recorded Congress.gov bill JSON path. Live Apple lookup: pass --live and a key.
@main
struct CongressDataDemo {
  static func main() async throws {
    let arguments = Array(CommandLine.arguments.dropFirst())
    if arguments.first == "--live" {
      #if canImport(Darwin)
      guard arguments.count == 2 else { throw DemoError.arguments }
      let client = CongressDataClient(apiKey: arguments[1], userAgent: "CongressDataDemo/1.0")
      let detail = try await client.bill(
        BillSourceIdentifier(congress: 6, number: "1", type: .houseBill))
      print(detail.bill.title)
      #else
      throw DemoError.arguments
      #endif
    } else {
      guard arguments.count == 1 else { throw DemoError.arguments }
      let bytes = try Data(contentsOf: URL(fileURLWithPath: arguments[0]))
      let detail = try JSONDecoder().decode(BillDetail.self, from: bytes)
      print(
        "Congress \(detail.bill.congress), source \(detail.bill.type.rawValue) \(detail.bill.number)"
      )
      print(detail.bill.title)
    }
  }

  enum DemoError: Error {
    case arguments
  }
}
