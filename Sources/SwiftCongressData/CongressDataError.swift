// Public execution APIs name Transport and TransportError.
@_exported import HTTPCore

/// A Congress.gov execution failure.
public enum CongressDataError: Error {
  /// A response could not be decoded with its declared model.
  case decoding
  /// A continuation is missing, invalid, or does not advance the same query.
  case invalidContinuation
  /// The networking layer rejected or failed the request, retaining status and headers.
  case transport(TransportError)

  static func mapped(_ error: TransportError) -> Self {
    if case .decode = error { return .decoding }
    return .transport(error)
  }
}
