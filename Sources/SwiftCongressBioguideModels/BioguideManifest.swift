/// Provenance and inventory for an externally extracted all-profile archive.
/// Count equality validates the supplied inventory, not its completeness against the live website.
public struct BioguideManifest: Codable, Hashable, Sendable {
  /// The SHA-256 of the original compressed archive, preserved as provenance.
  public let archiveSHA256: String
  /// Files in the supplied export order.
  public let entries: [BioguideManifestEntry]
  /// The supplied archive's expected unique-profile count.
  public let profileCount: Int
  /// The caller's archive retrieval instant, not a profile publication date.
  public let retrievedAt: String
  /// The official export page or supplied archive source URL.
  public let sourceURL: String
  /// Creates an immutable snapshot inventory for validation by BioguideImporter.
  public init(
    archiveSHA256: String, entries: [BioguideManifestEntry], profileCount: Int,
    retrievedAt: String, sourceURL: String
  ) {
    self.archiveSHA256 = archiveSHA256; self.entries = entries; self.profileCount = profileCount
    self.retrievedAt = retrievedAt; self.sourceURL = sourceURL
  }
}
