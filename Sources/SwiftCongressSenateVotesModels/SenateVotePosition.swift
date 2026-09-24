/// Open Senate position vocabulary; unknown source values remain representable.
public struct SenateVotePosition: Codable, Hashable, RawRepresentable, Sendable {
  /// The unmodified provider string.
  public let rawValue: String

  /// The source position Guilty.
  public static let guilty = Self(rawValue: "Guilty")
  /// The source position Nay.
  public static let nay = Self(rawValue: "Nay")
  /// The source position Not Guilty.
  public static let notGuilty = Self(rawValue: "Not Guilty")
  /// The source position Not Voting.
  public static let notVoting = Self(rawValue: "Not Voting")
  /// The source position Present.
  public static let present = Self(rawValue: "Present")
  /// The source position Yea.
  public static let yea = Self(rawValue: "Yea")

  /// Creates a known or future source position without normalization.
  public init(rawValue: String) { self.rawValue = rawValue }
  /// Decodes the source scalar string.
  public init(from decoder: any Decoder) throws {
    rawValue = try decoder.singleValueContainer().decode(String.self)
  }
  /// Encodes the original scalar string.
  public func encode(to encoder: any Encoder) throws {
    var c = encoder.singleValueContainer(); try c.encode(rawValue)
  }
}
