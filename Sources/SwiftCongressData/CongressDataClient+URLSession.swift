#if canImport(Darwin)
import HTTPURLSession

extension CongressDataClient {
  /// Creates an Apple-platform client with explicit credentials and application identity.
  public init(apiKey: String, userAgent: String) {
    self.init(
      configuration: .init(apiKey: apiKey, userAgent: userAgent), transport: URLSessionTransport())
  }
}
#endif
