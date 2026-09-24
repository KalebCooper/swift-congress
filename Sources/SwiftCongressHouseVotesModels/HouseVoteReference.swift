#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// A roll call explicitly linked by a House HTML inventory.
public struct HouseVoteReference: Codable, Hashable, Sendable {
  /// Coordinates parsed from the official link, never generated from an assumed range.
  public let identifier: HouseVoteIdentifier
  /// The original published link, which may use the historical HTTP CGI route.
  public let sourceLink: String
}
