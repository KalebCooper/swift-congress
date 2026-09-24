#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// A House roll call, including quorum and procedural votes, with its entire XML tree retained.
public struct HouseRollCall: Codable, Hashable, HouseResponse, Sendable {
  /// The source action date string, without a timezone or precision inference.
  public let actionDate: String?
  /// The source action time element, including its time-etz attribute.
  public let actionTime: HouseXMLNode?
  /// The source Congress number.
  public let congress: Int
  /// The published measure label, which can describe a quorum rather than a bill.
  public let legislation: String?
  /// The roll-call number in this document.
  public let number: Int
  /// The procedural question as published.
  public let question: String?
  /// The complete parsed source tree, including unknown fields and source totals.
  public let rawNode: HouseXMLNode
  /// Every voter row in source order, including duplicates and missing IDs.
  public let recordedVoters: [HouseVoter]
  /// The published result.
  public let result: String?
  /// The source session label, such as 2nd.
  public let session: String?
  /// Published aggregate totals by source field name; empty is distinct from missing.
  public let totals: [String: String]
  /// The source vote type, including QUORUM and open future values.
  public let voteType: String?

  /// Decodes one bounded source document without resolving any member identity.
  public static func decode(_ data: Data, sourceURL: URL) throws(HouseDecodingError) -> Self {
    let root = try HouseXMLCodec.decode(data)
    guard root.localName == "rollcall-vote", let metadata = root.child("vote-metadata"),
      let congress = metadata.child("congress").flatMap({ Int($0.text) }), congress > 0,
      let number = metadata.child("rollcall-num").flatMap({ Int($0.text) }), number > 0,
      let voters = root.child("vote-data")
    else { throw .invalidDocument }
    var rows: [HouseVoter] = []
    for (ordinal, node) in voters.children(named: "recorded-vote").enumerated() {
      rows.append(try HouseVoter(node: node, ordinal: ordinal))
    }
    var totals: [String: String] = [:]
    if let aggregate = metadata.child("vote-totals")?.child("totals-by-vote") {
      for content in aggregate.content {
        if case .element(let node) = content { totals[node.localName] = node.text }
      }
    }
    return Self(
      actionDate: metadata.child("action-date")?.text, actionTime: metadata.child("action-time"),
      congress: congress, legislation: metadata.child("legis-num")?.text, number: number,
      question: metadata.child("vote-question")?.text, rawNode: root, recordedVoters: rows,
      result: metadata.child("vote-result")?.text, session: metadata.child("session")?.text,
      totals: totals, voteType: metadata.child("vote-type")?.text)
  }
}

extension Endpoint where Response == HouseRollCall {
  /// Describes a published House XML file using the source's minimum three-digit numbering.
  public static func rollCall(_ identifier: HouseVoteIdentifier) -> Self {
    let number = String(identifier.number)
    let padded = String(repeating: "0", count: max(0, 3 - number.count)) + number
    return builtIn("/evs/\(identifier.year)/roll\(padded).xml")
  }
}

extension HouseVoteRequest where Response == HouseRollCall {
  /// Describes one roll call without downloading the rest of its year.
  public static func rollCall(_ identifier: HouseVoteIdentifier) -> Self {
    Self(endpoint: .rollCall(identifier))
  }
}
