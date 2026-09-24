#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// One published Senate Congress/session XML inventory.
public struct SenateVoteIndex: Codable, Hashable, SenateResponse, Sendable {
  /// Source Congress number.
  public let congress: Int
  /// Source Congress year label.
  public let congressYear: String?
  /// Complete inventory tree.
  public let rawNode: SenateXMLNode
  /// Source session number.
  public let session: Int
  /// Explicit entries in original order, including duplicates.
  public let votes: [SenateVoteReference]

  /// Reads a bounded inventory without generating an assumed numeric range.
  public static func decode(_ data: Data, sourceURL: URL) throws(SenateDecodingError) -> Self {
    let root = try SenateXMLCodec.decode(data)
    guard root.localName == "vote_summary",
      let congress = root.child("congress").flatMap({ Int($0.text) }), congress > 0,
      let session = root.child("session").flatMap({ Int($0.text) }), (1...2).contains(session),
      let records = root.child("votes")
    else { throw .invalidDocument }
    var votes: [SenateVoteReference] = []
    for node in records.children(named: "vote") {
      guard let sourceNumber = node.child("vote_number")?.text, let number = Int(sourceNumber),
        let identifier = try? SenateVoteIdentifier(
          congress: congress, number: number, session: session)
      else { throw .invalidDocument }
      votes.append(
        SenateVoteReference(
          identifier: identifier, issue: node.child("issue")?.text,
          question: node.child("question"), rawNode: node, result: node.child("result")?.text,
          sourceNumber: sourceNumber, title: node.child("title")?.text,
          voteDate: node.child("vote_date")?.text))
    }
    return Self(
      congress: congress, congressYear: root.child("congress_year")?.text, rawNode: root,
      session: session, votes: votes)
  }
}

extension Endpoint where Response == SenateVoteIndex {
  /// Describes a Senate session inventory without retrieving any linked votes.
  public static func index(congress: Int, session: Int) throws(SenateInputError) -> Self {
    _ = try SenateVoteIdentifier(congress: congress, number: 1, session: session)
    return builtIn("/legislative/LIS/roll_call_lists/vote_menu_\(congress)_\(session).xml")
  }
}
extension SenateVoteRequest where Response == SenateVoteIndex {
  /// Describes one session inventory.
  public static func index(congress: Int, session: Int) throws(SenateInputError) -> Self {
    Self(endpoint: try .index(congress: congress, session: session))
  }
}
