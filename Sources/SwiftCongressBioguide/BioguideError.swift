/// A supplied Bioguide snapshot failed validation or reading.
public enum BioguideError: Error, Hashable, Sendable {
  /// The consuming task was cancelled.
  case cancelled
  /// The profile bytes differ from the supplied length or SHA-256.
  case corruptProfile(String)
  /// JSON does not match the profile contract.
  case decoding(String)
  /// The directory is inaccessible, changed, or contains a symbolic link or unexpected file.
  case invalidDirectory
  /// Counts, paths, digests, or identifiers in the manifest are invalid or duplicated.
  case invalidManifest
  /// A profile's source identifier differs from its manifest identity.
  case mismatchedIdentifier(String)
}
