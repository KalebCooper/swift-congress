#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import HTTPCore
import HTTPTypes
import SwiftCongressHouseVotesModels

/// Retrieves independent House indexes and vote documents through an injected transport.
/// Redirects are refused, retries are opt-in, and no eager year/session traversal is hidden here.
public struct HouseVotesClient: Sendable {
  /// Maximum bytes retained for one source document.
  public let maximumResponseBytes: Int
  /// Explicit application identity.
  public let userAgent: String
  private let client: HTTPClient

  /// Creates a client with a bounded source body and injected clock and transport.
  public init(
    clock: any Clock<Duration> = ContinuousClock(), maximumResponseBytes: Int = 16_777_216,
    retryPolicy: RetryPolicy = .disabled, transport: any Transport, userAgent: String
  ) {
    self.maximumResponseBytes = maximumResponseBytes; self.userAgent = userAgent
    guard let base = URL(string: "https://clerk.house.gov") else {
      preconditionFailure("The source origin is a valid URL.")
    }
    client = HTTPClient(
      baseURL: base, clock: clock, redirectPolicy: .never, retryPolicy: retryPolicy,
      transport: transport)
  }

  /// Retrieves one document and retains the exact bytes used by its source-specific decoder.
  /// - Throws: `HouseVotesError` for HTTP, size, cancellation, or source-decoding failures.
  public func response<Value: HouseResponse>(for endpoint: Endpoint<Value>)
    async throws(HouseVotesError) -> SourceResponse<Value>
  {
    guard !Task.isCancelled else { throw .transport(.cancelled) }
    guard maximumResponseBytes > 0 else { throw .responseTooLarge }
    let response: StreamedResponse
    do throws(TransportError) {
      response = try await client.streamResponse(
        Request(headers: [.userAgent: userAgent], path: endpoint.path))
    } catch { throw .transport(error) }
    var bytes = Data()
    do {
      for try await chunk in response.body {
        guard !Task.isCancelled else { throw HouseVotesError.transport(.cancelled) }
        guard chunk.count <= maximumResponseBytes - bytes.count else {
          throw HouseVotesError.responseTooLarge
        }
        bytes.append(chunk)
      }
    } catch let error as HouseVotesError { throw error } catch let error as TransportError {
      throw .transport(error)
    } catch { throw .decoding(.invalidDocument) }
    guard !Task.isCancelled else { throw .transport(.cancelled) }
    let value: Value
    do { value = try await Self.decode(bytes, as: Value.self, sourceURL: endpoint.url) } catch {
      if Task.isCancelled { throw .transport(.cancelled) }; throw .decoding(error)
    }
    return SourceResponse(
      body: bytes,
      headers: response.headers.map { SourceHeader(name: $0.name.rawName, value: $0.value) },
      status: response.status.code, value: value)
  }

  /// Executes one typed endpoint with the same source codec and error mapping.
  public func send<Value: HouseResponse>(_ endpoint: Endpoint<Value>) async throws(HouseVotesError)
    -> Value
  {
    try await response(for: endpoint).value
  }

  /// Executes one inspectable request through send(_:).
  public func value<Value: HouseResponse>(for request: HouseVoteRequest<Value>)
    async throws(HouseVotesError) -> Value
  {
    switch request.resolution {
    case .endpoint(let endpoint): try await send(endpoint)
    }
  }

  @concurrent
  private static func decode<Value: HouseResponse>(
    _ data: Data, as type: Value.Type, sourceURL: URL
  )
    async throws(HouseDecodingError) -> Value
  { try Value.decode(data, sourceURL: sourceURL) }
}
