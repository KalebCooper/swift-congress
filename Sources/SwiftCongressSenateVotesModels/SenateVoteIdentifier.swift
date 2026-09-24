#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Invalid Senate source coordinates.
public enum SenateInputError: Error, Hashable, Sendable {
  /// Congress, session, or vote number is outside the source coordinate domain.
  case invalidIdentifier
}

/// A Senate LIS vote identity; it is independent of a House year and roll number.
public struct SenateVoteIdentifier: Codable, Hashable, Sendable {
  /// Positive Congress number.
  public let congress: Int
  /// Positive source vote number.
  public let number: Int
  /// Source session, 1 or 2.
  public let session: Int

  /// Validates coordinates without asserting a source file exists.
  public init(congress: Int, number: Int, session: Int) throws(SenateInputError) {
    guard congress > 0, number > 0, (1...2).contains(session) else { throw .invalidIdentifier }
    self.congress = congress; self.number = number; self.session = session
  }

  /// Decodes validated source coordinates.
  public init(from decoder: any Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    try self.init(
      congress: c.decode(Int.self, forKey: .congress), number: c.decode(Int.self, forKey: .number),
      session: c.decode(Int.self, forKey: .session))
  }
  private enum CodingKeys: String, CodingKey { case congress, number, session }
}
