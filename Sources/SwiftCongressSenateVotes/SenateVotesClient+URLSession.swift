#if canImport(Darwin)
import HTTPURLSession

extension SenateVotesClient {
  /// Creates an Apple-platform client with explicit application identity.
  public init(userAgent: String) {
    self.init(transport: URLSessionTransport(), userAgent: userAgent)
  }
}
#endif
