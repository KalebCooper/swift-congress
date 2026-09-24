#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// One published voter row. Duplicate names remain separate by row ordinal.
public struct HouseVoter: Codable, Hashable, Sendable {
  /// The source's display name, without an inferred member match.
  public let name: String
  /// The optional source name-id attribute; historical rows may have no identifier.
  public let nameID: String?
  /// Party at the recorded vote, if present.
  public let party: String?
  /// The original position vocabulary, including Present and unknown future values.
  public let position: HouseVotePosition
  /// Every XML field and attribute for this row.
  public let rawNode: HouseXMLNode
  /// Zero-based position in the source voter array, not a person identity.
  public let rowOrdinal: Int
  /// State or territory as published.
  public let state: String?

  init(node: HouseXMLNode, ordinal: Int) throws(HouseDecodingError) {
    guard let person = node.child("legislator"), let vote = node.child("vote") else {
      throw .invalidDocument
    }
    name = person.text; nameID = person.attributes["name-id"]; party = person.attributes["party"]
    position = HouseVotePosition(rawValue: vote.text); rawNode = node; rowOrdinal = ordinal;
    state = person.attributes["state"]
  }
}
