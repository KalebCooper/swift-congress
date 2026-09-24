#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// One current Senate identity row. This is evidence from a dated current inventory.
public struct SenateMemberIdentity: Codable, Hashable, Sendable {
  /// Optional Bioguide identifier as explicitly published by the Senate.
  public let bioguideID: String?
  /// Required source LIS member identity.
  public let lisMemberID: String
  /// All current member fields, including name, party, state, committees, and office.
  public let rawNode: SenateXMLNode
}
