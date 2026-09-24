import Foundation
import SwiftCongressBioguide
import SwiftCongressBioguideModels

@main
struct CongressBioguideDemo {
  static func main() async throws {
    guard let path = CommandLine.arguments.dropFirst().first else { throw DemoError.arguments }
    let directory = URL(fileURLWithPath: path).resolvingSymlinksInPath()
    let manifest = try JSONDecoder().decode(
      BioguideManifest.self,
      from: Data(contentsOf: directory.appendingPathComponent("manifest.json")))
    let importer = try BioguideImporter(manifest: manifest)
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

  enum DemoError: Error {
    case arguments
  }
}
