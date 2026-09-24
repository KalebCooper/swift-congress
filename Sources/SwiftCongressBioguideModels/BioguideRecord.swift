#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// One verified profile with the exact source bytes and manifest identity behind it.
public struct BioguideRecord: Sendable {
  /// Original extracted JSON, without re-encoding.
  public let body: Data
  /// The verified manifest entry.
  public let entry: BioguideManifestEntry
  /// The decoded profile, including unknown fields and rights metadata.
  public let profile: BioguideProfile
  /// Creates one validated record receipt.
  public init(body: Data, entry: BioguideManifestEntry, profile: BioguideProfile) {
    self.body = body; self.entry = entry; self.profile = profile
  }
}
