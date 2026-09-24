#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Validated page bounds shared by Congress.gov inventories.
public struct CongressQuery: Hashable, Sendable {
  /// The requested page size, from 1 through 250.
  public let limit: Int
  /// The nonnegative initial offset.
  public let offset: Int

  /// Uses the provider's default page size and first offset.
  public init() { limit = 20; offset = 0 }

  /// Validates explicit pagination bounds.
  /// - Throws: `CongressInputError.invalidQuery` for an invalid bound.
  public init(limit: Int, offset: Int = 0) throws(CongressInputError) {
    guard (1...250).contains(limit), offset >= 0 else { throw .invalidQuery }
    self.limit = limit; self.offset = offset
  }
}
