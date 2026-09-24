#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// A Senate vote retaining nomination, amendment, procedural, and source count information.
public struct SenateRollCall: Codable, Hashable, SenateResponse, Sendable {
  /// Amendment relationships exactly as published, when present.
  public let amendment: SenateXMLNode?
  /// Published Congress year, independent of modification time.
  public let congressYear: String?
  /// Counts by original field name; an empty value is distinct from an absent one.
  public let counts: [String: String]
  /// Source document metadata, which need not identify a bill.
  public let document: SenateXMLNode?
  /// Validated source Congress/session/vote coordinates.
  public let identifier: SenateVoteIdentifier
  /// Published majority requirement, including fractions.
  public let majorityRequirement: String?
  /// Modification date string, absent in some historical records.
  public let modifyDate: String?
  /// Original procedural question.
  public let question: String?
  /// Complete source XML tree, retaining mixed content and unknown fields.
  public let rawNode: SenateXMLNode
  /// All voters in source order, without deduplication or inferred identity.
  public let recordedVoters: [SenateVoter]
  /// Source result label.
  public let result: String?
  /// Published title.
  public let title: String?
  /// Original vote date string, without timezone inference.
  public let voteDate: String?

  /// Decodes one source document, never joining current identity data into historical votes.
  public static func decode(_ data: Data, sourceURL: URL) throws(SenateDecodingError) -> Self {
    let root = try SenateXMLCodec.decode(data)
    guard root.localName == "roll_call_vote",
      let congress = root.child("congress").flatMap({ Int($0.text) }),
      let number = root.child("vote_number").flatMap({ Int($0.text) }),
      let session = root.child("session").flatMap({ Int($0.text) }),
      let identifier = try? SenateVoteIdentifier(
        congress: congress, number: number, session: session),
      let members = root.child("members")
    else { throw .invalidDocument }
    var voters: [SenateVoter] = []
    for (ordinal, node) in members.children(named: "member").enumerated() {
      voters.append(try SenateVoter(node: node, ordinal: ordinal))
    }
    var counts: [String: String] = [:]
    for item in root.child("count")?.content ?? [] {
      if case .element(let node) = item { counts[node.localName] = node.text }
    }
    return Self(
      amendment: root.child("amendment"), congressYear: root.child("congress_year")?.text,
      counts: counts, document: root.child("document"), identifier: identifier,
      majorityRequirement: root.child("majority_requirement")?.text,
      modifyDate: root.child("modify_date")?.text,
      question: root.child("question")?.text, rawNode: root, recordedVoters: voters,
      result: root.child("vote_result")?.text, title: root.child("vote_title")?.text,
      voteDate: root.child("vote_date")?.text)
  }
}

extension Endpoint where Response == SenateRollCall {
  /// Describes one Senate XML vote using the source's minimum five-digit vote number.
  public static func rollCall(_ identifier: SenateVoteIdentifier) -> Self {
    let raw = String(identifier.number)
    let number = String(repeating: "0", count: max(0, 5 - raw.count)) + raw
    return builtIn(
      "/legislative/LIS/roll_call_votes/vote\(identifier.congress)\(identifier.session)/vote_\(identifier.congress)_\(identifier.session)_\(number).xml"
    )
  }
}
extension SenateVoteRequest where Response == SenateRollCall {
  /// Describes one independent roll call.
  public static func rollCall(_ identifier: SenateVoteIdentifier) -> Self {
    Self(endpoint: .rollCall(identifier))
  }
}
