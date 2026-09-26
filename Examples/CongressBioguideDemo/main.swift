import Foundation
import SwiftCongressBioguide
import SwiftCongressBioguideModels

@main
struct CongressBioguideDemo {
  /// Verifies every profile in an export directory, or lists the positions matching a filter.
  /// - Throws: `DemoError.arguments` when no export directory is given or the filter is malformed,
  ///   `BioguideInputError.invalidCongress` for a Congress number below 1, a Foundation read or
  ///   decoding error when the first argument is not a directory holding `manifest.json`, and
  ///   `BioguideError` from the import itself.
  static func main() async throws {
    let arguments = CommandLine.arguments.dropFirst()
    guard let path = arguments.first else { throw DemoError.arguments }
    let directory = URL(fileURLWithPath: path).resolvingSymlinksInPath()
    let manifest = try JSONDecoder().decode(
      BioguideManifest.self,
      from: Data(contentsOf: directory.appendingPathComponent("manifest.json")))
    let importer = try BioguideImporter(manifest: manifest)

    if let query = try parsedQuery(from: arguments.dropFirst()) {
      var matches = 0
      for try await record in importer.records(in: directory, matching: query) {
        for position in record.profile.positions(matching: query) {
          matches += 1
          let congress = position.congressAffiliation?.congress?.name ?? "no published Congress"
          print("\(record.entry.identifier): \(congress)")
        }
      }
      print("Matching positions: \(matches)")
      return
    }

    var count = 0
    var bodies: Set<String> = []
    for try await record in importer.records(in: directory) {
      count += 1
      for position in record.profile.jobPositions {
        if let body = position.congressAffiliation?.congress?.congressType { bodies.insert(body) }
      }
    }
    print("Verified \(count) profiles; bodies: \(bodies.sorted().joined(separator: ", "))")
    print("Archive SHA-256: \(manifest.archiveSHA256)")
  }

  /// Parses an optional `--congress <n> --body <type> [--job <name>] [--region <code>]` filter.
  /// - Parameter arguments: The command-line arguments following the export directory path.
  /// - Returns: The query, or nil when no filter arguments were given.
  /// - Throws: `DemoError.arguments` for an unrecognized or repeated flag, a flag missing its
  ///   value, a non-integer `--congress`, or a filter missing `--congress` or `--body`;
  ///   `BioguideInputError.invalidCongress` for a `--congress` value below 1.
  static func parsedQuery(from arguments: ArraySlice<String>) throws -> BioguideServiceQuery? {
    guard !arguments.isEmpty else { return nil }
    var congressNumber: Int?
    var congressType: String?
    var jobName: String?
    var regionCode: String?
    var iterator = arguments.makeIterator()
    while let flag = iterator.next() {
      guard let value = iterator.next() else { throw DemoError.arguments }
      switch flag {
      case "--body":
        guard congressType == nil else { throw DemoError.arguments }
        congressType = value
      case "--congress":
        guard congressNumber == nil, let number = Int(value) else { throw DemoError.arguments }
        congressNumber = number
      case "--job":
        guard jobName == nil else { throw DemoError.arguments }
        jobName = value
      case "--region":
        guard regionCode == nil else { throw DemoError.arguments }
        regionCode = value
      default: throw DemoError.arguments
      }
    }
    guard let congressNumber, let congressType else { throw DemoError.arguments }
    let congress = try BioguideCongressIdentifier(
      congressType: BioguideCongressType(rawValue: congressType), number: congressNumber)
    return BioguideServiceQuery(
      congress: congress, job: jobName.map(BioguideJobName.init(rawValue:)), regionCode: regionCode)
  }

  enum DemoError: Error {
    case arguments
  }
}
