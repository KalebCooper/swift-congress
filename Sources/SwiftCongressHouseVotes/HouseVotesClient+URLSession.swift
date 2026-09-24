#if canImport(Darwin)
import HTTPURLSession

extension HouseVotesClient {
  /// Creates an Apple-platform client with explicit application identity.
  public init(userAgent: String) {
    self.init(transport: URLSessionTransport(), userAgent: userAgent)
  }
}
#endif
