/// Explicit Congress.gov credentials and application identity.
public struct CongressDataConfiguration: Sendable {
  /// The API.data.gov key, sent only in X-Api-Key.
  public let apiKey: String
  /// The application identity sent as User-Agent.
  public let userAgent: String
  /// Creates required request configuration without reading environment variables.
  public init(apiKey: String, userAgent: String) {
    self.apiKey = apiKey; self.userAgent = userAgent
  }
}
