/// An immutable Senate source operation, with no implicit year or session download.
public struct SenateVoteRequest<Response>: Hashable, Sendable {
  /// The complete single-document operation for a custom executor.
  public enum Resolution: Hashable, Sendable {
    /// Retrieve and decode exactly one endpoint.
    case endpoint(Endpoint<Response>)
  }
  /// The inspectable operation.
  public let resolution: Resolution
  /// Creates a consumer-defined single-document request.
  public init(endpoint: Endpoint<Response>) { resolution = .endpoint(endpoint) }
}
