/// Invalid House source coordinates.
public enum HouseInputError: Error, Hashable, Sendable {
  /// The year or roll number is not a positive source coordinate.
  case invalidIdentifier
}

/// A House Clerk roll-call file identity; year and roll number are both required.
public struct HouseVoteIdentifier: Codable, Hashable, Sendable {
  /// The positive roll number.
  public let number: Int
  /// The source year, independent of Congress/session labels in the document.
  public let year: Int

  /// Creates validated source coordinates without asserting a file exists.
  public init(number: Int, year: Int) throws(HouseInputError) {
    guard number > 0, (1...9999).contains(year) else { throw .invalidIdentifier }
    self.number = number; self.year = year
  }

  /// Decodes and validates source coordinates.
  public init(from decoder: any Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    try self.init(
      number: c.decode(Int.self, forKey: .number), year: c.decode(Int.self, forKey: .year))
  }

  private enum CodingKeys: String, CodingKey { case number, year }
}
