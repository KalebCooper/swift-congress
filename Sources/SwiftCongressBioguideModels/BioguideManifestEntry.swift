/// One extracted file in a supplied Bioguide snapshot.
public struct BioguideManifestEntry: Codable, Hashable, Sendable {
  /// The uncompressed byte count.
  public let byteCount: Int
  /// A single relative filename; directory traversal is forbidden by the importer.
  public let filename: String
  /// The source Bioguide identifier expected inside this file.
  public let identifier: String
  /// The lowercase SHA-256 of the unmodified extracted bytes.
  public let sha256: String
  /// Describes one extracted profile and its expected digest.
  public init(byteCount: Int, filename: String, identifier: String, sha256: String) {
    self.byteCount = byteCount; self.filename = filename; self.identifier = identifier;
    self.sha256 = sha256
  }
}
