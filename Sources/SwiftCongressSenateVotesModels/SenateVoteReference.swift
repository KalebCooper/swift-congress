#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// One explicit entry in the Senate session inventory.
public struct SenateVoteReference: Codable, Hashable, Sendable {
  /// Congress/session coordinates from the containing inventory and this published vote number.
  public let identifier: SenateVoteIdentifier
  /// Measure, amendment, nomination, or other issue label as published.
  public let issue: String?
  /// The source question node, preserving nested measure text in order.
  public let question: SenateXMLNode?
  /// Complete inventory entry.
  public let rawNode: SenateXMLNode
  /// Source result label.
  public let result: String?
  /// Original zero-padded vote number.
  public let sourceNumber: String
  /// Published title.
  public let title: String?
  /// Source date string, which may omit the year.
  public let voteDate: String?
}
