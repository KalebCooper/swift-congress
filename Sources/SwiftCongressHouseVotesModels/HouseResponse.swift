#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// A source-specific response decodable without an SDK or transport.
public protocol HouseResponse: Sendable {
  /// Decodes the downloaded bytes using the request URL as explicit source context.
  static func decode(_ data: Data, sourceURL: URL) throws(HouseDecodingError) -> Self
}
