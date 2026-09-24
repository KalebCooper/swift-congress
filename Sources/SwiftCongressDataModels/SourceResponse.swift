#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// One response header, preserving repeated field names through array storage.
public struct SourceHeader: Codable, Hashable, Sendable {
  /// The response field name.
  public let name: String
  /// The field value as received.
  public let value: String
  /// Creates a portable response field.
  public init(name: String, value: String) { self.name = name; self.value = value }
}

/// Decoded data and the exact response bytes used to decode it.
/// Retrieval timestamps and durable hashing belong to the caller's ingestion receipt.
public struct SourceResponse<Value: Sendable>: Sendable {
  /// The original response bytes, without re-encoding.
  public let body: Data
  /// Response headers in received order.
  public let headers: [SourceHeader]
  /// The successful HTTP status code.
  public let status: Int
  /// The value decoded from body.
  public let value: Value
  /// Creates a receipt for one successful response.
  public init(body: Data, headers: [SourceHeader], status: Int, value: Value) {
    self.body = body; self.headers = headers; self.status = status; self.value = value
  }
}
