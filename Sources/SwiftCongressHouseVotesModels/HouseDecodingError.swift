/// Failure while reading one bounded House source document.
public enum HouseDecodingError: Error, Hashable, Sendable {
  /// The reading task was cancelled.
  case cancelled
  /// The document is malformed or lacks required source structure.
  case invalidDocument
  /// The document exceeds byte, depth, or element bounds.
  case limitExceeded
}
