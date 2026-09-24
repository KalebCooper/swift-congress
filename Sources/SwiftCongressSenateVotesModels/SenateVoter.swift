#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// One published Senate voter row, without a guessed Bioguide identity.
public struct SenateVoter: Codable, Hashable, Sendable {
  /// Source first name.
  public let firstName: String?
  /// Source display name.
  public let fullName: String
  /// Source last name.
  public let lastName: String?
  /// LIS identity as published; it is not a Bioguide identifier.
  public let lisMemberID: String?
  /// Party at this recorded vote.
  public let party: String?
  /// Unmodified position vocabulary, including unknown future values.
  public let position: SenateVotePosition
  /// All row elements and attributes, including unknown fields.
  public let rawNode: SenateXMLNode
  /// Zero-based source row ordinal, not a person identity.
  public let rowOrdinal: Int
  /// Source state label.
  public let state: String?

  init(node: SenateXMLNode, ordinal: Int) throws(SenateDecodingError) {
    guard let fullName = node.child("member_full"), let position = node.child("vote_cast") else {
      throw .invalidDocument
    }
    firstName = node.child("first_name")?.text; self.fullName = fullName.text
    lastName = node.child("last_name")?.text; lisMemberID = node.child("lis_member_id")?.text
    party = node.child("party")?.text; self.position = SenateVotePosition(rawValue: position.text);
    rawNode = node
    rowOrdinal = ordinal; state = node.child("state")?.text
  }
}
