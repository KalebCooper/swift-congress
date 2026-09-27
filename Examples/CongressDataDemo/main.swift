import Foundation
import SwiftCongressData
import SwiftCongressDataModels

// Offline: pass a recorded Congress.gov bill JSON path, a recorded member detail or member
// list page with --member/--members, or a recorded bill text-version page with --text. Live
// Apple lookup: pass --live and a key (bill route only).
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
    } else if arguments.first == "--member" {
      guard arguments.count == 2 else { throw DemoError.arguments }
      let bytes = try Data(contentsOf: URL(fileURLWithPath: arguments[1]))
      let detail = try JSONDecoder().decode(MemberDetail.self, from: bytes)
      printMember(detail.member)
    } else if arguments.first == "--members" {
      guard arguments.count == 2 else { throw DemoError.arguments }
      let bytes = try Data(contentsOf: URL(fileURLWithPath: arguments[1]))
      let page = try JSONDecoder().decode(MemberPage.self, from: bytes)
      print("pagination.count \(page.pagination.count)")
      for member in page.members {
        print("bioguideId \(member.bioguideId), name \(member.name)")
        for term in member.terms ?? [] {
          print(
            "  term chamber=\(term.chamber ?? "-") startYear=\(term.startYear.map(String.init) ?? "-") endYear=\(term.endYear.map(String.init) ?? "-")"
          )
        }
      }
    } else if arguments.first == "--text" {
      guard arguments.count == 2 else { throw DemoError.arguments }
      let bytes = try Data(contentsOf: URL(fileURLWithPath: arguments[1]))
      let page = try JSONDecoder().decode(BillTextVersionPage.self, from: bytes)
      print("pagination.count \(page.pagination.count)")
      for version in page.textVersions {
        print("type \(version.type ?? "-"), date \(version.date ?? "(none)")")
        for format in version.formats ?? [] {
          print("  format type=\(format.type ?? "-") url=\(format.url ?? "-")")
        }
      }
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

  static func printMember(_ member: MemberProfile) {
    print("bioguideId \(member.bioguideId)")
    print("directOrderName \(member.directOrderName ?? "-")")
    print("currentMember \(member.currentMember.map(String.init) ?? "-")")
    for term in member.terms ?? [] {
      print(
        "  term congress=\(term.congress.map(String.init) ?? "-") chamber=\(term.chamber ?? "-") district=\(term.district.map(String.init) ?? "-")"
      )
    }
    for key in ["addressInformation", "leadership", "partyHistory", "previousNames"] {
      print("  rawFields[\(key)] present: \(member.rawFields[key] != nil)")
    }
  }

  enum DemoError: Error {
    case arguments
  }
}
